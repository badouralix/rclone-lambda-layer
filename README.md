# Rclone Lambda Layer

[Rclone](https://github.com/rclone/rclone) is an rsync for cloud storage, including [S3](https://aws.amazon.com/s3), [GCS](https://cloud.google.com/storage), [pCloud](https://www.pcloud.com/eu) and so on.

This repository brings the power of rclone to aws lambda. It can be used along with [cron-based schedules](https://docs.aws.amazon.com/lambda/latest/dg/services-cloudwatchevents-expressions.html) for instance to synchronize multiple drives on a regular basis.

## Usage

Unfortunately no public layer is available. Fear no more, this Short snippet automatically provisions a custom layer containing rclone in your own AWS tenant.

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

## Example Lambda (NodeJS v20+)

Create a new lambda function:

- Runtime: NodeJS V20+ (arm64 likely preferred, amd64 should work fine too)
- **Important:** Attach the custom uploaded layer (with correct arch) to your lambda (I had to use layer ARN to add it in)
- **Important:** INCREASE the timeout for the newly created lamda (default 3 seconds) - the lambda will not be able to even complete a failed run in 3 seconds, so increase timeout to at least 60 seconds if not 5 minutes+.
- Tested 2024-Nov: A failed run (intentionally wrong password) completed in ~15 seconds. A successfull run completed a synced ~6GB/5000+ object vault in ~1.30minutes. Logs successfully showed correct statuses (info, warnings, errors, fatals).
- Below code uses a rclone "one-liner" that doesn't need a config file as all the needed values are provided within the command.
  - If you need config file, or want python, or a more featured example then [check here](https://github.com/badouralix/rclone-lambda-sync)

```js
// index.mjs

import { exec } from 'child_process';
import { promisify } from 'util';
const execAsync = promisify(exec);

function printLogs (entry) {
  const { level, msg, ...rest } = entry;

  switch (level) {
    case 'fatal':
      console.error(`FATAL:`, msg);
      break;
    case 'error':
      console.error(msg);
      break;
    case 'warning':
      console.warn(msg);
      break;
    case 'info':
      console.info(msg);
      break;
    default:
      console.debug("--DEBUG:", msg);
      break;
  }
}

export const handler = async (event) => {
  const rcloneCommand = `/opt/bin/rclone \
    sync \
    :b2:MyNiceBackBlazeVault :s3:MyCoolS3Vault \
    --s3-provider AWS \
    --s3-access-key-id BlahBlah-S3-AccessID \
    --s3-secret-access-key BlahBlah-S3-AccessKey \
    --s3-region us-west-2 \
    --b2-account BlahBlah-B2-AppKeyID \
    --b2-key BlahBlah-B2-AppKey \
    --use-json-log --verbose \
    --stats 10s`;

  let logs = [];

  console.info('Executing rclone command:');
  try {
    const { stdout, stderr } = await execAsync(rcloneCommand);

    // Parse rclone JSON logs from stdout
    const stdoutlogLines = stdout.trim().split('\n').filter(Boolean);
    stdoutlogLines.map((line) => {
      try {
        logs.push(JSON.parse(line));
        printLogs(JSON.parse(line));
      } catch (parseError) {
        console.error('Failed to parse log line', { line, error: parseError.message });
        return null;
      }
    }).filter(Boolean);

    // Parse rclone JSON logs from stderr
    const stderrlogLines = stderr.trim().split('\n').filter(Boolean);
    stderrlogLines.map((line) => {
      try {
        logs.push(JSON.parse(line));
        printLogs(JSON.parse(line));
      } catch (parseError) {
        console.error('Failed to parse log line', { line, error: parseError.message });
        return null;
      }
    }).filter(Boolean);

    // Optionally, extract summary information from the logs
    const summaryLog = logs.find(log => log.msg.includes('Transferred:'));
    const summary = summaryLog ? summaryLog.msg : 'No summary available';

    // Return the summary as the Lambda function response
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'Rclone sync completed successfully.',
        summary,
      }),
    };
  } catch (error) {
    // Attempt to parse any stderr output for error details
    const stderr = error.stderr || '';
    const stderrlogLines = stderr.trim().split('\n').filter(Boolean);
    stderrlogLines.map((line) => {
      try {
        logs.push(JSON.parse(line));
        printLogs(JSON.parse(line));
      } catch (parseError) {
        console.error('Failed to parse log line', { line, error: parseError.message });
        return null;
      }
    }).filter(Boolean);

    // Throw the error to indicate the Lambda function failed
    let finalError = logs.findLast((log) => log.level == "error" || log.level == "fatal")
    throw new Error(`${finalError.msg}`);
  }
};
```

## License

Unless explicitly stated to the contrary, all contents licensed under the [MIT License](LICENSE).
