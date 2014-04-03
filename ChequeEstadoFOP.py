#!/usr/bin/python
#Revisa estado FOP en servidor 
#Casep, Version inicial, 20120511

import commands
import sys

estado = commands.getoutput('csession ssmocapp2010 -UUSER "UEstadoFOP"')
perfdata = "4;9;0;0"

if estado == "1":
 print "FOP OK: Respuesta 0.5 Seg | Respuesta FOP 0.5 Seg."
 sys.exit(0)
else:
 print "FOP CRITICAL: FOP No responde | FOP No responde"
 sys.exit(2)

