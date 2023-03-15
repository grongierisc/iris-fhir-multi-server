FROM grafana/grafana:9.1.7

COPY ./data/grafana.db /var/lib/grafana/grafana.db
COPY ./grafana.ini /etc/grafana/grafana.ini
COPY ./datasource.yml /etc/grafana/provisioning/datasources/datasource.yml
COPY ./dashboard-provider.yml /etc/grafana/provisioning/dashboards/dashboard-provider.yml
COPY ./dashboard.json /var/lib/grafana/dashboards/dashboard.json
COPY ./dashboard-chu.json /var/lib/grafana/dashboards/dashboard-chu.json