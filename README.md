## 事前準備
権限エラーで時間を取られるのを防ぐため、最初に一括設定します。

『sudo chown -R ec2-user:ec2-user public/』


## STEP 01：初期セットアップ


### 1. SSHログイン
```
ssh ec2-user@{IPアドレス} -i {秘密鍵ファイルのパス}
```





## STEP 02：Docker環境構築


### 2. Dockerインストール

```
sudo yum install -y docker

sudo systemctl start docker

sudo systemctl enable docker

sudo usermod -a -G docker ec2-user
```
※ここで一度 exit して再ログインしてください。




### 3. Docker Composeインストール

```
sudo mkdir -p /usr/local/lib/docker/cli-plugins/

sudo curl -SL https://github.com/docker/compose/releases/download/v2.36.0/docker-

compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose

sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
```

## STEP 03：DB構築とファイル配置

### git cloneでGithubからソースコードを取得します。
```
git clone https://github.com/khayato2369/koukikadai.git
```
```
cd koukikadai
```
```
docker compose build
```

### 4. MySQLテーブル作成
```
docker compose exec mysql mysql example_db 
```

を実行し、SQLを貼り付けます。


１行ずつお願いします




### SQL

```sql
CREATE TABLE `access_logs` (`id` INT NOT NULL PRIMARY KEY AUTO_INCREMENT, `user_agent` TEXT NOT NULL, `remote_ip` TEXT NOT NULL, `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP);

CREATE TABLE `bbs_entries` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `user_id` INT UNSIGNED NOT NULL, `body` TEXT NOT NULL, `image_filename` TEXT DEFAULT NULL, `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP);

CREATE TABLE `user_relationships` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `followee_user_id` INT UNSIGNED NOT NULL, `follower_user_id` INT UNSIGNED NOT NULL, `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP);

CREATE TABLE `users` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, `name` TEXT NOT NULL, `email` TEXT NOT NULL, `password` TEXT NOT NULL, `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP);

ALTER TABLE `users` ADD COLUMN icon_filename TEXT DEFAULT NULL, ADD COLUMN introduction TEXT DEFAULT NULL, ADD COLUMN cover_filename TEXT DEFAULT NULL, ADD COLUMN birthday DATE DEFAULT NULL;
```



### 5. ファイル転送

ローカルPCのターミナルから実行します。

```
scp -i {秘密鍵のパス} -r {publicディレクトリのパス} ec2-user@{IPアドレス}:/home/ec2-user/
```


### 6. パーミッション修正

```
chmod 755 public/
chmod 644 public/*.php
chmod 755 public/setting/
chmod 644 public/setting/*.php
```




## STEP 04：起動


### 7. コンテナ起動

```
docker compose up -d --build
```


### 8. ブラウザ確認

```
http://{パブリックIPアドレス}/signup.php
```


