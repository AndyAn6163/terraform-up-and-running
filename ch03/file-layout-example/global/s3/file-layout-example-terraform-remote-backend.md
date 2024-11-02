# 如何部署

因為我們要設定 Terraform Backend 為 s3 前必須要先部署 s3 跟 DynamoDB table 上去，才能夠設定 backend 為 s3

因此我們要設定兩步驟:

第一步驟: 以 local backend 部署 s3 跟 DynammoDB table

1. main-s3.tf 設定 terraform backend 為 local 並註解掉 terraform backend 為 s3
2. 執行 terraform init -> 就會使用 local backend
3. 執行 terraform apply -> 部署 s3 跟 DynamoDB table

第二步驟: 加上 remote backend

1. main-s3.tf 設定 terraform backend 為 s3
2. 執行 terraform init -migrate-state -backend-config ./backend.hcl -> 就會使用 remote backend s3

   Pre-existing state was found while migrating the previous "local" backend to the
   newly configured "s3" backend. No existing state was found in the newly
   configured "s3" backend. Do you want to copy this state to the new "s3"
   backend? Enter "yes" to copy and "no" to start with an empty state.

   透過 terraform init 重新設定 backend 到 s3，並且透過 -migrate-state 將狀態從 local 複製到 s3

3. s3 出現 object : global/s3/terraform.tfstate

# 如何刪除

1. 註解掉 main-s3.tf 中 terraform backend 為 s3
2. 註解掉 main-s3.tf 中 s3 prevent_destroy = true
3. 執行 terraform init -migrate-state

   因為註解掉 backend s3，所以會重新設定 backend 為 local，並且透過 -migrate-state 將狀態從 s3 複製到 local

4. main-s3.tf 中 s3 增加 force_destroy = true

   如果不設定，當 terraform destroy 時會出現
   The bucket you tried to delete is not empty. You must delete all versions in the bucket

5. 執行 terraform destroy

# web-server-cluster 加上 remote backend

1. 因為 web-server-cluster 的 main.tf 沒有要部署 s3 或者 DynamoDB 因此沒有如上兩步驟的問題
2. 只要 remote backend 所使用的 s3 跟 DynamoDB 已經部署上去，web-server-cluster 直接加上 remote backend 即可
