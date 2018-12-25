# EC2 Auto Metric Alarm

Launch された EC2 インスタンスに対して、インスタンスのタグに設定された CloudWatch Alarm の定義 (以降、 `監視定義` と呼ぶ) を動的に適用する Lambda 関数です。  
Auto-Scaling の `Launch`, `Terminate` イベントを検知し、 EC2 インスタンスの増減に応じて動的に CloudWatch Alarm を作成・削除します。

適用する `監視定義` はあらかじめ S3 バケットの所定のパスにアップロードしておく必要があります。
`監視定義` は後述する `監視定義スキーマ` に従って記述された `JSON` または `YAML` の `ERB テンプレート` です。
以降、 `監視定義` が記載された S3 オブジェクトを `監視定義テンプレート` と呼びます。

この Lambda 関数は `Serverless Application Model (SAM)` を利用して実装されています。

## 動機 / Motivation

Auto-Scaling のメトリクスに対して CloudWatch Metric Alarm を設定することは可能だが、個々のインスタンスのメトリクスに対して Alarm を設定した場合、 Auto-Scaling 下のインスタンスだと増減の際に無効になってしまう。

Auto-Scaling に対応した監視サービスを利用すれば監視は可能だが、Prometheus や NewRelic などの監視システムを利用するためには、ライセンスやツールのノウハウが必要になる。  
この SAM は、 AWS のネイティブサービスのみを利用した監視を実現するためのもので、EC2 の監視が CloudWatch のカスタムメトリクスやアラームなどの課金のみで実現できる。

## 用語 / Glossary

|名称|英語表記|説明|例|
|---|---|---|---|
|監視定義|Alarm Definition|CloudWatch Alarm の定義のこと。後述する `監視定義テンプレート` に インスタンスID などが binding されたもの。各定義には一意な `監視定義ID` を割り当てる。||
|監視定義ID|Alarm Definition ID|`監視定義` ごとに割り当てられた任意の ID 文字列。| `emergency-cpu-util` |
|監視定義バケット|Alarm Definitions Bucket| `監視定義テンプレート` を格納する S3 バケット。| `ec2-auto-metric-alarm-definitions` |
|監視定義名|Alarm Definition Name|EC2 インスタンスにタグで設定される `監視定義テンプレート` のファイル名。| `cpu-util` |
|監視定義テンプレート|Alarm Definition Template|単一または複数の `監視定義` を記載した `ERB` テンプレートファイル。また、そのファイルを表す `S3 オブジェクト` のこと。このテンプレートに インスタンスID などが bind されて `監視定義` のエンティティ(実体)となる。| `s3://ec2-auto-metric-alarm-definitions/cpu-util` |
|通知種別|Notification Type|緊急か通常かを表す通知の種別。`監視定義` ごとに通知種別を指定することができ、通知先のトピックを振り分ける。| `emergency` or `ordinary` |

## 事前作成が必要な AWS リソース / Pre-Requirement AWS Resources

* 監視定義バケット / Alarm Definitions Bucket

  * `監視定義テンプレート` オブジェクトを格納する S3 バケット。  
  * Lambda 関数はローンチ(または削除)された EC2 インスタンスの所定のタグを参照し、このバケットに存在する監視定義テンプレートを取得する。
  * このバケットのオブジェクトに対する読み取り権限は SAM デプロイ時に自動的に Lambda 関数の IAM ロールに設定される。

* 緊急通知用の SNS トピック / Emergency Notification Topic

  * 通知種別が `emergency` の監視定義における CloudWatch Alarm の通知先となる SNS トピック。

* 通常通知用の SNS トピック / Ordinary Notification Topic

  * 通知種別が `ordinary` の監視定義における CloudWatch Alarm の通知先となる SNS トピック。

* 監視定義テンプレート S3 オブジェクト / Alarm Definition Templates

  * 監視定義バケットにアップロードされた `監視定義テンプレート` ファイル。
  * `YAML` のテンプレートを利用する場合は `Content-Type` を `text/yaml` など、 `yaml` を含む Mime-Type にしてアップロードする必要があります。
  * いくつかのサンプルテンプレートはリポジトリに含まれています。監視要件によってテンプレートを追加・修正してアップロードしてください。

## SAM のパラメータ / SAM Parameters

* FunctionName

    SAM で生成される Lambda 関数の名前。デフォルトは `ec2-auto-metric-alarms` 。

* EmergencyTopicArn

    `通知種別` が `emergency` の通知を行う SNS トピックの ARN 。

* OrdinaryTopicArn

    `通知種別` が `ordinary` の通知を行う SNS トピックの ARN 。

* DefinitionBucketName

    `監視定義バケット` のバケット名。

* DefinitionObjectPrefix

    `監視定義テンプレート` が格納されている `監視定義バケット` の S3 Object Prefix。デフォルトは `/` 。

* DefinitionTagKey

    `監視定義名` が設定されている EC2 インスタンスのタグキー。デフォルトは `AlarmDefinitionName` 。

* LogLevel

    Lambda 関数内の Ruby logger のログレベル。デフォルトは `INFO` 。

* LogRetensionInDays

    生成される Lambda 関数の LogGroup の保持日数。デフォルトは `30` 日。

## この関数の挙動 / Behavior

### インスタンス起動時 / Behavior when launched EC2 instance

Auto-Scaling によってインスタンスが起動した際の振る舞いは以下の通りです。

1. CloudWatch Event によって Auto-Scaling イベントを検知
1. CloudWatch Event Rule によって Lambda 関数が実行される
1. イベントに含まれる instance-id により、インスタンスのタグから `監視定義名` を取得
1. 監視定義名をもとに、S3 バケットに格納されている `監視定義テンプレート` をダウンロードして parse / evaluation する
1. インスタンスの情報をテンプレートに埋め込み、CloudWatch Alarm を生成する

### インスタンス削除時 / Behavior when terminated EC2 instance

Auto-Scaling によってインスタンスが削除された際の振る舞いは以下の通りです。

1. CloudWatch Event によって Auto-Scaling イベントを検知
1. CloudWatch Event Rule によって Lambda 関数が実行される
1. イベントに含まれる instance-id により、インスタンスのタグから `監視定義名` を取得
1. 監視定義名をもとに、S3 バケットに格納されている `監視定義テンプレート` をダウンロードして parse / evaluation する
1. インスタンスの情報から Alarm を特定し、 CloudWatch Alarm を削除する

### その他のケース / Behavior when other cases

すでに起動済みのインスタンスに対しては、Auto-Scaling イベントでの適用ができないため、初回デプロイ時や手動でインスタンスを起動した際に Lambda を手動実行することを想定しています。Lambda を直接実行した際の挙動は以下の通りです。

1. すべての起動済みインスタンスから `監視定義名` のタグが設定されたインスタンスを取得
1. 以降は起動時と同様、取得したインスタンスのタグ値からテンプレートを取得し、 CloudWatch Alarm を作成する

## 監視定義スキーマ / Alarm Definition Schema

`監視定義テンプレート` のスキーマを CPU 監視のサンプルテンプレートをもとに解説します。

```json
{
    "name": "cpu-util",
    "description": "Watch CPUUtilization of EC2 instance",
    "alarm_definitions": [
        {
            "alarm_id": "emergency-cpu-util",
            "notification_type": "emergency",
            "alarm_name": "ec2-<%= instance.id %>-emergency-cpu-util",
            "alarm_description": "<%= instance.name %> CPUUtilization greater than 90 for 10 minutes",
            "namespace": "AWS/EC2",
            "dimensions": [
                {
                    "name": "InstanceId",
                    "value": "<%= instance.id%>"
                }
            ],
            "metric_name": "CPUUtilization",
            "statistic": "Average",
            "threshold": 90,
            "comparison_operator": "GreaterThanThreshold",
            "period": 300,
            "evaluation_periods": 2,
            "datapoints_to_alarm": 2,
            "treat_missing_data": "ignore"
        }
    ],
    "include_definitions": [],
    "ignore_alarm_ids": []
}
```

* $.name
    
    `監視定義テンプレート`名を表す任意の名前です。テンプレートを人が読んだときのヒントでしかなく、挙動には何も影響しません。

* $.description

    `監視定義テンプレート` の説明です。こちらも挙動には何も影響しません。

* $.alarm_definitions

    `監視定義` の本体です。複数設定できます。同じ監視項目に対して異なる閾値と `通知種別` を定義する場合は１つの `監視定義テンプレート` 内に同居したほうが管理が楽なため、複数設定可能としています。

* $.alarm_definitions.*.alarm_id

    `監視定義ID` です。同じ ID を持つ `監視定義` は、どちらか一方しか適用されません。後述の `ignore_alarm_ids` で `監視定義` を除外する際にはこの `alarm_id` を指定します。

* $.alarm_definitions.*.notification_type

    通知種別で、 `emergency` または `ordinary` を指定します。指定しなかった場合は `ordinary` となります。実際の挙動としては、 `emergency` 以外はすべて `ordinary` として扱われます。

* $.alarm_definitions.*.alarm_name **他**

    `alarm_id` と `notification_type` 以外の項目は、 CloudWatch の [PutMetricAlarm API](https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/API_PutMetricAlarm.html) リクエストと同じものです。`ok_actions` と `alarm_actions` を指定した場合、 Lambda 関数の環境変数に設定された通知先トピックを上書きします。

* $.include_definitions.*

    `監視定義名` を指定することで、指定した `監視定義` を継承します。値は `監視定義名` の文字列配列です。指定された `監視定義名` に該当する `監視定義テンプレート` が `監視定義バケット` にない場合はエラーにはならずに無視されます。

* $.ignore_alarm_ids.*

    `include_definitions` で他のテンプレートを継承した際に、不要な `監視定義` を除外するための `監視定義ID` の文字列配列です。例えば、ステージング環境などで緊急通知の `監視定義` だけを除外したい場合などに利用します。存在しない `監視定義ID` を指定した場合はエラーにならずに無視されます。

### ERB テンプレート変数 `instance` / ERB template variable `instance`

ERB テンプレートの `bindings` には `instance` が含まれます。  
この `instance` は `Aws::EC2::Instance` のラッパーオブジェクトで、以下の属性とメソッドを追加で定義してあります（実際のコードを簡略化しています）。

```ruby
def tag_value(tag_key, default_value)
    @instance.tags.find { |tag| tag.key == tag_key }&.value || default_value
end

def name
    tag_value('Name')
end

def alarm_definition
    tag_value(ENV['ALARM_DEFINITION_TAG_KEY'])
end
```

`Aws::EC2::Instance` のラッパーなので、 ERB テンプレートの中で `aws-sdk` を利用することで EC2 以外の情報も（Lambda 関数の IAM ロールに権限さえあれば）取得可能です。

```erb
<%
root_volume_id = instance.block_device_mappings.find do |mapping|
  mapping.ebs.volume_id
end
root_volume = Aws::EC2::Resource.new.volume(root_volume_id)
%>
```

### YAML での定義 / Use YAML

YAML の場合、reference と anchor が利用できます。上記スキーマにない項目は無視されるので、 `alarm_definitions` の外に定義した anchor を使い回すことが可能です。

```yaml
---
_alarm_definition: &cpu_util
  namespace: 'AWS/EC2'
  dimensions:
    - name: InstanceId
      value: <%= instance.id %>
  metric_name: CPUUtilization
  statistic: Average
  threshold: 90
  comparison_operator: GreaterThanThreshold
  period: 300
  treat_missing_data: ignore

name: cpu-util
description: Watch CPUUtilization of EC2 instance
alarm_definitions:
  - <<: *cpu_util
    alarm_id: ordinary-cpu-util
    alarm_name: ec2-<%= instance.id %>-ordinary-cpu-util
    alarm_description: >
      <%= instance.name %> CPUUtilization greater than 90 for 10 minutes
    evaluation_periods: 2
    datapoints_to_alarm: 2
  - <<: *cpu_util
    alarm_id: emergency-cpu-util
    notification_type: emergency
    alarm_name: ec2-<%= instance.id %>-emergency-cpu-util
    alarm_description: >
      <%= instance.name %> CPUUtilization greater than 90 for 30 minutes
    evaluation_periods: 6
    datapoints_to_alarm: 6
```

## Development

### Structure of directories

```console
.
├── README.md                   <-- This instructions file
├── src                         <-- Source code for a lambda function
│  └── function.rb              <-- Lambda function code
├── Gemfile                     <-- Ruby dependencies
├── Makefile.example            <-- Makfile example
├── sample-definitions          <-- Sample alarm definition files
├── template.yaml               <-- SAM template
└── spec                        <-- Unit tests
    └── spec_helper.rb
```

### Requirements

* AWS CLI already configured with at least PowerUser permission
* [Ruby](https://www.ruby-lang.org/en/documentation/installation/) 2.5 installed

### Setup

```bash
cp Makefile.example Makefile
make install
```

### Testing

```bash
# AWS の API はすべて Mock 化されています
make rspec
```

## Deployment

```
# edit your Makefile
make deploy
```