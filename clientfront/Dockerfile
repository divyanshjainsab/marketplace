FROM node:20-bookworm

WORKDIR /app

COPY clientfront/package.json clientfront/package-lock.json ./
RUN npm install

COPY clientfront/ .
COPY docker/clientfront/entrypoint.sh /usr/local/bin/clientfront-entrypoint
RUN chmod +x /usr/local/bin/clientfront-entrypoint

EXPOSE 3000

ENTRYPOINT ["clientfront-entrypoint"]
CMD ["npm", "run", "dev", "--", "--hostname", "0.0.0.0", "--port", "3000"]
