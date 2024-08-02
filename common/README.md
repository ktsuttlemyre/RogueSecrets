# RogueArgs

```
~/RogueCLI $ ./rogue ./secrets/get.sh ggjs --debug=trace --debug="break off"

Rogue[rogue]  Debug set to trace
Rogue[rogue]  docker compose (v2) is installed.
RogueDebugger[65 ./rogue]<<< :args_debug
RogueDebugger[Type:Array]>>> trace break off
RogueDebugger[65 ./rogue]<<< ::args_debug
RogueDebugger[Type:Array]>>> trace break off
RogueDebugger[65 ./rogue]<<< :json:args_debug
[
  "trace",
  "break off"
]
```

Use `--RogueArgs_debug` to debug RogueArgs via the console function


### Devnote:
if you uncomment echo inside the console function you will get parsing information output
```
~/RogueCLI $ ./rogue ./secrets/get.sh ggjs --debug=trace --debug="break off"

number of arguments received 4
parsing flag ./secrets/get.sh
parsing flag ggjs
parsing flag --debug=trace
pushing key/value [debug] and [trace]
parsing flag --debug=break off
pushing key/value [debug] and [break off]
Rogue[rogue]  Debug set to trace
debug entry = trace
debug entry = break off
```


# RoguePrompt

