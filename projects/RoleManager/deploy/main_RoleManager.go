package main

import (
	"flag"

	"bitbucket.org/wemade-tree/waffle/modules/console/compile"
	"bitbucket.org/wemade-tree/waffle/modules/deploy/config"
	"bitbucket.org/wemade-tree/waffle/modules/deploy/utils"
	"bitbucket.org/wemade-tree/waffle/modules/migration"
	"bitbucket.org/wemade-tree/waffle/modules/sender/network"
	"bitbucket.org/wemade-tree/waffle/projects/RoleManager/deploy/scripts"
	log "bitbucket.org/wemade-tree/wemix-go-tree/common/clog"
)

var ConsoleDir = utils.GetWorkDir("../projects/RoleManager/console.sol")

func main() {
	cfgPath := flag.String("config", "", "conf file path")
	keystore := flag.String("keystore", "", "keystore path")
	threshold := flag.Int("threshold", 1, "threshold")
	filter := flag.String("filter", "", "filters")
	from := flag.String("from", "", "from address")
	dataDir := flag.String("dataDir", "./data", "data dir")
	isRecoreMode := flag.Bool("record", false, "isRecoreMode")
	isTestMode := flag.Bool("test", false, "isTestMode")
	flag.Parse()

	cMap, cAry := compile.CompileContractsBoth(ConsoleDir)
	if cfg, err := config.NewConfig(*cfgPath); err != nil {
		log.Error(err)
	} else {
		netObj := network.NewNetwork(cfg, *from, *dataDir, cMap, cAry, *cfgPath, *keystore, *threshold, false, false, *isRecoreMode, *isTestMode)
		scripts.InitMigration()
		migration.NewMigration(cAry, *filter, "", netObj, scripts.MigrationMap).Run()
	}
}
