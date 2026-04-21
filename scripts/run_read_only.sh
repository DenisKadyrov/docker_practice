docker run -d \
  --name my-nginx-practice \
  -p 8080:80 \
  --memory=50m \
  --cpus=0.5 \
  --read-only \
  --tmpfs /var/cache/nginx \
  --tmpfs /var/run \
  --tmpfs /tmp \
  -v "$PWD/nginx_logs:/var/log/nginx" \
  my-nginx-practice:v1
