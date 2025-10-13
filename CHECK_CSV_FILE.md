# Check CSV File - Quick Commands

## 1. Check if CSV exists

**In VirtualBox Linux, run:**

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
ls -la wormhole-attack-results.csv
```

**Expected if file exists:**
```
-rw-r--r-- 1 kanisa kanisa 1234 Oct 13 05:20 wormhole-attack-results.csv
```

**If file doesn't exist:**
```
ls: cannot access 'wormhole-attack-results.csv': No such file or directory
```

## 2. Check all CSV files in directory

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
ls -la *.csv
```

## 3. Search for CSV anywhere

```bash
cd ~/Downloads/ns-allinone-3.35/ns-3.35
find . -name "*.csv" -ls
```

## 4. Check if ExportStatistics is actually called

Add debug output to see if the code reaches that point.

---

**Please run these commands and send me the output!**
