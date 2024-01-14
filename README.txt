BREAZU Radu-Mihai, 343C3

                                README

Dependențe software
Pentru a putea rula aplicația, este nevoie ca pe sistemul de calcul să fie
instalate Docker și python3 (împreună cu pachetele cx_Oracle, numpy și
matplotlib).

Mod de rulare
Pornirea containerului Docker
După ce s-a verificat instalarea dependențelor menționate mai sus, se deschide
aplicația Docker Desktop (sau se pornește direct din terminal daemonul de
Docker), se deschide un terminal în directorul rădăcină, se rulează comanda
"docker build [-t tag] ." ("-t tag" este opțional), care creează o imagine de
Docker aferentă configurației din Dockerfile, se pornește un container Docker
din imagine folosind comenzile "docker image ls" și
"docker run --name [nume container] -d -p 1521:1521 -p 5500:5500
[nume tag sau imagine]". Nu este exclus ca pornirea containerului să dureze în
jur de 2 minute.

Popularea bazei de date
După pornirea containerului (care poate fi verificată folosind comanda
"docker ps", inspectând coloana STATUS -- trebuie să apară HEALTHY), se rulează
comenzile din scripturile create_tables.sql, populate_tables.sql și
create_procedures.sql (atât scripturile, cât și comenzile trebuie rulate în
ordine). Rularea acestor scripturi a fost testată manual, folosind o conexiune
creată din VS Code (cu extensia Oracle instalată), drept care aceasta este metoda
recomandată pentru rularea lor. Desigur, scripturile pot fi rulate și din SQL
Developer (într-o manieră asemănătoare).

Rularea aplicației
Pentru a rula aplicația, se folosește fie comanda "python3 src/app.py", dată din
directorul rădăcină, fie "python3 app.py" dată din directorul src.