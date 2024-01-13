FROM container-registry.oracle.com/database/express:21.3.0-xe
ENV ORACLE_PWD=parolaAiaPuternica!
ENV ORACLE_CHARACTERSET=AL32UTF8
ENV ORACLE_SID=XE
ENV ORACLE_ALLOW_REMOTE=true
EXPOSE 1521
EXPOSE 5500
WORKDIR /app
COPY scripts/ ./scripts/
RUN sqlplus -s system/parolaAiaPuternica!@XE as sysdba @scripts/create_tables.sql
RUN sqlplus -s system/parolaAiaPuternica!@XE as sysdba @scripts/populate_tables.sql
RUN sqlplus -s system/parolaAiaPuternica!@XE as sysdba @scripts/create_procedures.sql