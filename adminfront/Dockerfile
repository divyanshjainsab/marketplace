FROM node:20-bookworm

WORKDIR /app

COPY adminfront/package.json adminfront/package-lock.json ./
RUN npm ci

COPY adminfront/ .
COPY docker/clientfront/entrypoint.sh /usr/local/bin/adminfront-entrypoint
RUN chmod +x /usr/local/bin/adminfront-entrypoint

EXPOSE 3000

ENTRYPOINT ["adminfront-entrypoint"]
CMD ["npm", "run", "dev", "--", "--hostname", "0.0.0.0", "--port", "3000"]
