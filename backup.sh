#!/bin/bash

set -o errexit -o nounset -o pipefail

digitalocean_s3() {
    s3cmd -s --access_key="$DIGITAL_OCEAN_ACCESS_KEY" --secret_key="$DIGITAL_OCEAN_SECRET_KEY" --host="$DIGITAL_OCEAN_ENDPOINT" --host-bucket="%(bucket)s.$DIGITAL_OCEAN_ENDPOINT" "$@"
}

bucket_exists() {
    digitalocean_s3 ls s3://$DIGITAL_OCEAN_BUCKET_NAME &> /dev/null
}

ensure_bucket_exists() {
    if bucket_exists; then
        return
    fi    
    echo "Bucket $DIGITAL_OCEAN_BUCKET_NAME doesn't exist. Exiting..."
    exit 1
}

pg_dump_database() {
    pg_dump  --no-owner --no-privileges --clean --if-exists --quote-all-identifiers "$DATABASE_URL"
}

upload_to_bucket() {
    # if the zipped backup file is larger than 50 GB add the --expected-size option
    # see https://docs.aws.amazon.com/cli/latest/reference/s3/cp.html
    digitalocean_s3 put - "s3://$DIGITAL_OCEAN_BUCKET_NAME/$FILE_PREFIX-backup-$(date +%Y-%m-%dT%H_%M_%S.sql.gz)"
}

main() {
    ensure_bucket_exists
    echo "Taking backup and uploading it to DigitalOcean..."
    pg_dump_database | gzip | upload_to_bucket
    echo "Done."
}

main
