# Was ist ProSeed? | _What is ProSeed?_
ProSeed 17 ist eine Sammlung von Funktionen zur Erweiterung von Sämaschinen im Landwirtschafts Simulator 17:  
_ProSeed 17 is a bundle of functions to enhance sowing machines in Farming Simulator 17:_

* Fahrgassen erstellen (optional mit Vorauflaufmarkierung)  
_Create tramlines (with optional pre-emergence marking)_
* Halbseitige Abschaltung für korrekte Fahrgassen  
_Halfside shutoff for correct tramlines_
* Akkustische Statussignale  
_Accoustic status signals_
* Düngefunktion abschalten  
_Shutoff fertilizing_
* Spuranzeiger einzeln schalten  
_Control ridge markers separately_

## Installation
FS17_ProSeed.zip in den Mod-Ordner kopieren. Die Mod wird automatisch in alle Sämaschinen eingefügt.  
*Copy FS17_ProSeed.zip into your mod folder. The mod is automatically inserted into all seeders.*

## Bedienung | _Usage_
Die Bedienung erfolgt über Tasten und per Maus.  
_You need to use keys and mouse to control the mod._

Taste / _Key_ | Modus / _Mode_ | Funktion / _function_
------------ | ------------- | -------------
Numpad 7 | - | HUD öffnen/schließen, _open/close HUD_
Numpad 8 | manuell, _manual_ | Fahrgassen an/aus, _tramlines on/off_
Numpad 8 | semi | Spurzähler +1, _track counter +1_
Numpad 8 | auto | Spurzähler pausieren, _pause track counter_
Numpad 8 | GPS* | GPS Spurzähler zurücksetzen, _reset GPS track counter_
Numpad 9 | - | halbseitige Abschaltung wechseln (rechts, links, aus), _toggle halfside shutoff (right, left, off)_
y, _z_ | - | Spurreisser links, _left ridgemarker_
l_shift + y, *l_shift + z* | - |Spurreisser rechts, _right ridgemarker_

![ProSeed HUD](../gh-pages/images/ProSeed_HUD.png)

Schaltfläche(n), _Button(s)_ | Funktionen / _functions_
---------- | ---------------
HUD 1 | Einstellungen öffnen/schließen, _open/close settings_
HUD 2 | HUD schließen, _close HUD_
HUD 3 | Modus der Fahrgassenschaltung ändern, _change tramline mode_
HUD 4 | Fahrgassen-Abstand ändern, _change tramline distance_
HUD 5 | Spurzähler ändern, _change track counter_
HUD 6 | Düngefunktion an/aus, _fertilizing on/off_
HUD 7 | Vorauflaufmarkierung an/aus, _pre-emergence marking on/off_
HUD 8 | Arbeitsbreite an GPS-Mod senden, _send work width to GPS-Mod_
HUD 9 | Akkustische Signale an/aus, _accoustic signals on/off_

Manche Funktionen/Schaltflächen stehen nur zur Verfügung, wenn das entsprechende Modul im Einstellungsfenster aktiviert ist.  
_Some functions / buttons are only available if the corresponding module is activated in the settings window._

Modus, _mode_ | Bedienung, _operation_
------------- | ----------------------
manuell, _manual_ | Fahrgassen werden vom Fahrer durch drücken von Numpad 8 ***aktiviert/deaktiviert***, _tramlines are ***activated/deactivated*** by the driver by pressing Numpad 8_
semi | benötigten Fahrgassen-Abstand einstellen (HUD 4), Spuren werden vom Fahrer durch drücken von Numpad 8 ***gezählt*** (Korrektur über HUD 5 möglich), Fahrgassen werden automatisch aktiviert/deaktiviert, _set the required tramline distance (HUD 4), driver ***counts*** tracks by pressing Numpad 8 (use HUD 5 for correction), tramlines are activated/deactivated automatically_
auto | benötigten Fahrgassen-Abstand einstellen (HUD 4), Spuren werden automatisch gezählt (Korrektur über HUD 5 möglich), Fahrgassen werden automatisch aktiviert/deaktiviert, _set the required tramline distance (HUD 4), tracks are counted automatically (use HUD 5 for correction), tramlines are activated/deactivated automatically_
GPS* | benötigten Fahrgassen-Abstand einstellen (HUD 4), Arbeitsbreite an GPS-Mod senden (HUD 8), Spuren werden automatisch von GPS gezählt, Fahrgassen werden automatisch aktiviert/deaktiviert, es können Spuren ausgelassen werden, _set the required tramline distance (HUD 4), send work width to GPS-Mod (HUD 8), tracks are counted automatically by GPS, tramlines are activated/deactivated, tracks can be skipped_
*GPS-Mod 5.xx von upsidedown wird benötigt und muss aktiviert sein  
_GPS-Mod 5.xx from upsidedown is required and must be activated_

Die Arbeitsbreite muss im GPS an die vorgegebene Arbeitsbreite von ProSeed angeglichen werden (HUD 8 oder im GPS-Mod)!  
_The working width in GPS has to be adjusted to the given working width of ProSeed (HUD 8 or within GPS-Mod)!_

Bei gerader Anzahl von Fahrten (HUD 5, z.B. "x / 4") muss immer mit einer halben Bahn begonnen werden, ansonsten stimmt später der Abstand zum Feldrand nicht. Nutze dazu die halbseitige Abschaltung (Numpad 9). Bei Verwendung von GPS ist dabei die erste Spur am Feldrand auszurichten und mit Numpad 8 auf 0 (GPS) bzw. 1 (ProSeed) zu setzen. Für die zweite Bahn wird die GPS-Spur in dessen HUD um die halbe Arbeitsbreite in Richtung Feldrand verschoben.  
_If the number of drives (HUD 5, e.g. "x / 4") is even, always start with a half track, otherwise the distance to the edge of the field will not be correct. Use halfside shutoff for the first track. When using GPS, the first track must be aligned at the edge of the field and set to 0 (GPS) or 1 (ProSeed) using Numpad 8. For the second track shift the GPS track in its HUD by half the working width towards the field edge._  

Eine Darstellung möglicher Arbeitbreiten und Abstände sind in dieser PDF-Datei beschrieben: [Download](../gh-pages/images/ProSeed.pdf)  
_A description of possible working widths and distances is given in this PDF file: [Download](../gh-pages/images/ProSeed.pdf)_  

Die Zustände der Fahrgassen, der halbseitigen Abschaltung sowie Spurreisser werden im HUD entsprechend dargestellt.  
_The states of tramlines, the half-side shutoff, as well as the ridgemarkers are displayed in the HUD._

### Authors and Contributors
gotchTOM (@gotchTOM), webalizer (@webalizer-gt)  
GreenEye, Manuel Leithner

### Support or Contact
On github or planet-ls.de
