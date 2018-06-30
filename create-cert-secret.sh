kubectl create secret tls paul-steele.com --key /etc/letsencrypt/live/paul-steele.com/privkey.pem --cert /etc/letsencrypt/live/paul-steele.com/fullchain.pem

kubectl create secret tls hell-yeah.org --key /etc/letsencrypt/live/hell-yeah.org/privkey.pem --cert /etc/letsencrypt/live/hell-yeah.org/fullchain.pem
