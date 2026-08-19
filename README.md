# notesApp

Service that allow to write your notes in notes.txt and receive it back through endpoint /

endpoints: "/" for receive a notes.txt info back and "/healtz" for docker health check

app.py receives a PORT can set custom port for your service and NOTES_FILE to set custom location to your notes.txt file

to start service you need to:

1. git clone this project
2. set your config settings in app.py file
3. write your notes in NOTES_FILE
4. start service with command "python3 app.py"
