FROM elixir:latest
VOLUME /var/qdfms/db/
RUN cd /tmp && wget https://github.com/pfriedma/QDFMS/archive/refs/heads/master.zip && \
cd /var && unzip /tmp/master.zip && cd /var/QDFMS-master/app/qdfms && \
mix local.hex --force && mix deps.get && \
cd apps/inventory && mix amnesia.create -d Database --disk && \
cd ../qdfms_web && mix local.rebar --force && mix phx.gen.cert
RUN printf 'config :qdfms_web, QdfmsWeb.Endpoint,\n    https: [\n      port: 443,\n      cipher_suite: :strong,\n    certfile: "priv/cert/selfsigned.pem",\n     keyfile: "priv/cert/selfsigned_key.pem"\n]' >> /var/QDFMS-master/app/qdfms/config/dev.exs 
WORKDIR /var/QDFMS-master/app/qdfms/apps/qdfms_web/
ENTRYPOINT ["/bin/bash","-c","/usr/local/bin/iex -S mix phx.server"]
EXPOSE 443