# Rclone Lambda Layer

[Rclone](https://github.com/rclone/rclone) is an rsync for cloud storage, including [S3](https://aws.amazon.com/s3), [GCS](https://cloud.google.com/storage), [pCloud](https://www.pcloud.com/eu) and so on.

This repository brings the power of rclone to aws lambda. It can be used along with [cron-based schedules](https://docs.aws.amazon.com/lambda/latest/dg/services-cloudwatchevents-expressions.html) for instance to synchronize multiple drives on a regular basis.

## Usage

Unfortunately no public layer is available. Fear no more, this one-liner automatically provisions one in your own account.

1. Launch [AWS CloudShell](https://console.aws.amazon.com/cloudshell) and run below commands:

    ```bash
    # Retrieve this code
    git clone https://github.com/badouralix/rclone-lambda-layer.git
    cd rclone-lambda-layer

    # Build AND publish lambda layer to your AWS Account (make script does both automatically)
    make all-amd64
    make all-arm64
    ```

1. Add the newly added layer to your Lambda function. You may have to provide the specific ARN of your newly created layer to the lambda function.

    ![arn:aws:lambda:eu-west-3:123456789012:layer:rclone:4](https://user-images.githubusercontent.com/19719047/114280672-b0cdf380-9a3a-11eb-8850-c2dfe59ad97b.png)

## License

Unless explicitly stated to the contrary, all contents licensed under the [MIT License](LICENSE).
