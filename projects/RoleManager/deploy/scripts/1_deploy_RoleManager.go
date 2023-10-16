package scripts

import (
	"math/big"

	net "bitbucket.org/wemade-tree/waffle/modules/deploy/network"
	"bitbucket.org/wemade-tree/waffle/modules/sender/network"
)

type RoleManager struct {
	*network.Deploy
}

func (p *RoleManager) Init(contract *net.Contract) {
	p.Deploy = network.NewDeploy(contract)
}

func (p *RoleManager) Loaded() bool {
	return p.Deploy != nil
}

func (p *RoleManager) Deployment(n network.INetwork) *net.Receipt {
	value := big.NewInt(0)
	return n.Deploy(
		p.Contract,
		value,
		// params
	)
}

func (p *RoleManager) Validation(n network.INetwork) {
}

func (p *RoleManager) Execution(n network.INetwork) error {
	return nil
}
