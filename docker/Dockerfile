FROM nginx:alpine

COPY apps/canopy-explorer /usr/share/nginx/html/canopy-explorer
COPY apps/quantumshield-terminal /usr/share/nginx/html/quantumshield-terminal
COPY apps/sovereign-dpi-portal /usr/share/nginx/html/sovereign-dpi-portal
COPY docker/nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000 3001 3002
CMD ["nginx", "-g", "daemon off;"]
