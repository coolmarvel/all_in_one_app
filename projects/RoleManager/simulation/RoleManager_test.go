package test

import (
	"testing"

	"bitbucket.org/wemade-tree/waffle/modules/backend"
	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/assert"
)

func DeployContract(t *testing.T, wemix common.Address) *backend.Client {
	client := backend.NewClient(t)

	client.Backend.Commit()

	//constructor input
	backend.NewContract(t, "../contracts/RoleManager.sol", "RoleManager").Deploy(t, client)
	return client
}

/**
*	TestDeploy
*	Desc: test deploy RoleManager contract successfully
**/
func TestDeploy(t *testing.T) {
	t.Run("TestDeploy01_deploySuccessfully", func(t *testing.T) {
		client := DeployContract(t, common.Address{})
		_, ok := client.Contracts["RoleManager"]

		assert.Equal(t, ok, true)
	})
}

/**
*	TestGrantRole
*	Desc: test grantRole function
*	1. check grant new role successfully
*	2. check grant exist role successfully
*	3. check can not grant twice
*	4. check can not grant non-admin key
**/
func TestGrantRole(t *testing.T) {
	/**
	*	case01: TestGrantRole01_grantNewRole
	*	- gen new account
	*	- gen new role name
	*	- grant role
	*	- check account has new role
	 */
	t.Run("TestGrantRole01_grantNewRole", func(t *testing.T) {
		client := DeployContract(t, common.Address{})
		roleManager := client.Contracts["RoleManager"]

		// new role name
		var newRole [32]byte
		copy(newRole[:], []byte("new minter role"))

		addressList := make([]common.Address, 10)
		for i := range addressList {
			// gen key
			roleAddress, _ := backend.GenKey()
			addressList[i] = roleAddress

			// grant
			receipt := roleManager.Execute(t, nil, "grantRole", newRole, roleAddress)
			logs := roleManager.FindLog(t, receipt.Logs, "RoleGranted", false)

			assert.Equal(t, receipt.Status, uint64(1))
			var logRole [32]byte
			copy(logRole[:], logs[0])
			assert.Equal(t, logRole, newRole)
			assert.Equal(t, common.BytesToAddress(logs[1]), roleAddress)
			assert.Equal(t, common.BytesToAddress(logs[2]), client.Owner)
		}

		// verify
		for _, e := range addressList {
			isGranted := roleManager.LowCall1(t, "hasRole", newRole, e)
			assert.Equal(t, isGranted, true)
		}

		list := roleManager.LowCall1(t, "getRoleList", newRole).([]common.Address)

		assert.Equal(t, list, addressList)
	})

	/**
	*	case02: TestGrantRole02_grantExistRole
	*	- gen new account
	*	- gen new role name
	*	- grant new role
	*	- check account has new role
	*	- gen another account
	*	- grant role
	*	- check new account has role
	 */
	t.Run("TestGrantRole02_grantExistRole", func(t *testing.T) {
		client := DeployContract(t, common.Address{})
		roleManager := client.Contracts["RoleManager"]

		// gen key
		roleAddress, _ := backend.GenKey()

		// new role name
		var newRole [32]byte
		copy(newRole[:], []byte("new minter role"))

		// grant
		backend.ExpectedSuccess(t, roleManager, nil, "grantRole", newRole, roleAddress)

		// verify
		isGranted := roleManager.LowCall1(t, "hasRole", newRole, roleAddress)
		assert.Equal(t, isGranted, true)

		// gen another key
		roleAddress2, _ := backend.GenKey()

		// grant
		receipt := roleManager.Execute(t, nil, "grantRole", newRole, roleAddress2)

		logs := roleManager.FindLog(t, receipt.Logs, "RoleGranted", false)

		assert.Equal(t, receipt.Status, uint64(1))
		var logRole [32]byte
		copy(logRole[:], logs[0])
		assert.Equal(t, logRole, newRole)
		assert.Equal(t, common.BytesToAddress(logs[1]), roleAddress2)
		assert.Equal(t, common.BytesToAddress(logs[2]), client.Owner)

		// verify
		isGranted = roleManager.LowCall1(t, "hasRole", newRole, roleAddress2)
		assert.Equal(t, isGranted, true)

	})

	/**
	*	case03: TestGrantRole03_grantRoleTwice
	*	- gen new account
	*	- gen new role name
	*	- grant new role
	*	- check account has new role
	*	- gen another account
	*	- grant role again
	*	- check do not emit
	 */
	t.Run("TestGrantRole03_grantRoleTwice", func(t *testing.T) {
		client := DeployContract(t, common.Address{})
		roleManager := client.Contracts["RoleManager"]

		// gen key
		roleAddress, _ := backend.GenKey()

		// new role name
		var newRole [32]byte
		copy(newRole[:], []byte("new minter role"))

		// grant
		backend.ExpectedSuccess(t, roleManager, nil, "grantRole", newRole, roleAddress)

		// verify
		isGranted := roleManager.LowCall1(t, "hasRole", newRole, roleAddress)
		assert.Equal(t, isGranted, true)

		// grant again
		receipt := roleManager.Execute(t, nil, "grantRole", newRole, roleAddress)

		logs := roleManager.FindLog(t, receipt.Logs, "RoleGranted", false)

		assert.Equal(t, len(logs), 0)
	})

	/**
	*	case04: TestGrantRole04_nonAdminRole
	*	- gen new account
	*	- gen new role name
	*	- grant new role with non-admin role
	*	- check fail
	 */
	t.Run("TestGrantRole04_nonAdminRole", func(t *testing.T) {
		client := DeployContract(t, common.Address{})
		roleManager := client.Contracts["RoleManager"]

		// gen key
		roleAddress, _ := backend.GenKey()

		// new role name
		var newRole [32]byte
		copy(newRole[:], []byte("new minter role"))

		// non-admin account
		_, nonAdminKey := backend.GenKeyWithFaucet(t, client, backend.ToWei(1))

		// grant non-admin key
		backend.ExpectedFail(t, roleManager, nonAdminKey, "grantRole", newRole, roleAddress)
	})
}

/**
*	TestRevokeRole
*	Desc: test revokeRole function
*	1. check revoke role successfully
*	2. check can not revoke non-admin key
**/
func TestRevokeRole(t *testing.T) {
	/**
	*	case01: TestRevokeRole01_revokeRoleSuccessfully
	*	- gen new account
	*	- gen new role name
	*	- grant role
	*	- check account has new role
	*	- revoke role
	*	- check revoke successfully
	 */
	t.Run("TestRevokeRole01_revokeRoleSuccessfully", func(t *testing.T) {
		client := DeployContract(t, common.Address{})
		roleManager := client.Contracts["RoleManager"]

		// new role name
		var newRole [32]byte
		copy(newRole[:], []byte("new minter role"))

		addressList := make([]common.Address, 10)
		var logRole [32]byte
		for i := range addressList {
			// gen key
			roleAddress, _ := backend.GenKey()
			addressList[i] = roleAddress

			// grant
			receipt := roleManager.Execute(t, nil, "grantRole", newRole, roleAddress)
			logs := roleManager.FindLog(t, receipt.Logs, "RoleGranted", false)

			assert.Equal(t, receipt.Status, uint64(1))

			copy(logRole[:], logs[0])
			assert.Equal(t, logRole, newRole)
			assert.Equal(t, common.BytesToAddress(logs[1]), roleAddress)
			assert.Equal(t, common.BytesToAddress(logs[2]), client.Owner)
		}

		// verify
		for _, e := range addressList {
			isGranted := roleManager.LowCall1(t, "hasRole", newRole, e)
			assert.Equal(t, isGranted, true)
		}

		list := roleManager.LowCall1(t, "getRoleList", newRole).([]common.Address)

		assert.Equal(t, list, addressList)

		t.Log(list)
		t.Log(len(list))
		// revoke first
		receipt := roleManager.Execute(t, nil, "revokeRole", newRole, addressList[0])

		logs := roleManager.FindLog(t, receipt.Logs, "RoleRevoked", false)

		assert.Equal(t, receipt.Status, uint64(1))

		copy(logRole[:], logs[0])
		assert.Equal(t, logRole, newRole)
		assert.Equal(t, common.BytesToAddress(logs[1]), addressList[0])
		assert.Equal(t, common.BytesToAddress(logs[2]), client.Owner)

		// verify
		isGranted := roleManager.LowCall1(t, "hasRole", newRole, addressList[0])
		assert.Equal(t, isGranted, false)

		list = roleManager.LowCall1(t, "getRoleList", newRole).([]common.Address)

		for _, e := range list {
			assert.NotEqual(t, e, addressList[0])
		}
		t.Log(list)
		t.Log(len(list))
		// revoke last
		receipt = roleManager.Execute(t, nil, "revokeRole", newRole, addressList[len(addressList)-1])

		logs = roleManager.FindLog(t, receipt.Logs, "RoleRevoked", false)

		assert.Equal(t, receipt.Status, uint64(1))

		copy(logRole[:], logs[0])
		assert.Equal(t, logRole, newRole)
		assert.Equal(t, common.BytesToAddress(logs[1]), addressList[len(addressList)-1])
		assert.Equal(t, common.BytesToAddress(logs[2]), client.Owner)

		// verify
		isGranted = roleManager.LowCall1(t, "hasRole", newRole, addressList[len(addressList)-1])
		assert.Equal(t, isGranted, false)

		list = roleManager.LowCall1(t, "getRoleList", newRole).([]common.Address)

		for _, e := range list {
			assert.NotEqual(t, e, addressList[len(addressList)-1])
		}
		t.Log(list)
		t.Log(len(list))
		// revoke mid
		receipt = roleManager.Execute(t, nil, "revokeRole", newRole, addressList[(len(addressList)-1)/2])

		logs = roleManager.FindLog(t, receipt.Logs, "RoleRevoked", false)

		assert.Equal(t, receipt.Status, uint64(1))

		copy(logRole[:], logs[0])
		assert.Equal(t, logRole, newRole)
		assert.Equal(t, common.BytesToAddress(logs[1]), addressList[(len(addressList)-1)/2])
		assert.Equal(t, common.BytesToAddress(logs[2]), client.Owner)

		// verify
		isGranted = roleManager.LowCall1(t, "hasRole", newRole, addressList[(len(addressList)-1)/2])
		assert.Equal(t, isGranted, false)

		list = roleManager.LowCall1(t, "getRoleList", newRole).([]common.Address)

		for _, e := range list {
			assert.NotEqual(t, e, addressList[(len(addressList)-1)/2])
		}
		t.Log(list)
		t.Log(len(list))
	})

	/**
	*	case02: TestRevokeRole02_revokeNonAdminRole
	*	- gen new account
	*	- gen new role name
	*	- grant role
	*	- check account has new role
	*	- revoke role with non-admin role
	*	- check fail
	 */
	t.Run("TestRevokeRole02_revokeNonAdminRole", func(t *testing.T) {
		client := DeployContract(t, common.Address{})
		roleManager := client.Contracts["RoleManager"]

		// gen key
		roleAddress, _ := backend.GenKey()

		// new role name
		var newRole [32]byte
		copy(newRole[:], []byte("new minter role"))

		// non-admin account
		_, nonAdminKey := backend.GenKeyWithFaucet(t, client, backend.ToWei(1))

		// grant
		receipt := roleManager.Execute(t, nil, "grantRole", newRole, roleAddress)

		logs := roleManager.FindLog(t, receipt.Logs, "RoleGranted", false)

		assert.Equal(t, receipt.Status, uint64(1))

		var logRole [32]byte
		copy(logRole[:], logs[0])
		assert.Equal(t, logRole, newRole)
		assert.Equal(t, common.BytesToAddress(logs[1]), roleAddress)
		assert.Equal(t, common.BytesToAddress(logs[2]), client.Owner)

		// verify
		isGranted := roleManager.LowCall1(t, "hasRole", newRole, roleAddress)
		assert.Equal(t, isGranted, true)

		// revoke
		backend.ExpectedFail(t, roleManager, nonAdminKey, "revokeRole", newRole, roleAddress)

	})
}

/**
*	TestRenounceRole
*	Desc: test renounceRole function
*	1. check renounce role successfully
*	2. check can not renounce non-admin key
**/
func TestRenounceRole(t *testing.T) {
	/**
	*	case01: TestRenounceRole01_renounceRoleSuccessfully
	*	- gen new account
	*	- gen new role name
	*	- grant role
	*	- check account has new role
	*	- renounce role
	*	- check revoke successfully
	 */
	t.Run("TestRenounceRole01_renounceRoleSuccessfully", func(t *testing.T) {
		client := DeployContract(t, common.Address{})
		roleManager := client.Contracts["RoleManager"]

		// gen key
		roleAddress, roleKey := backend.GenKeyWithFaucet(t, client, backend.ToWei(1))

		// new role name
		var newRole [32]byte
		copy(newRole[:], []byte("new minter role"))

		// grant
		receipt := roleManager.Execute(t, nil, "grantRole", newRole, roleAddress)

		logs := roleManager.FindLog(t, receipt.Logs, "RoleGranted", false)

		assert.Equal(t, receipt.Status, uint64(1))

		var logRole [32]byte
		copy(logRole[:], logs[0])
		assert.Equal(t, logRole, newRole)
		assert.Equal(t, common.BytesToAddress(logs[1]), roleAddress)
		assert.Equal(t, common.BytesToAddress(logs[2]), client.Owner)

		// verify
		isGranted := roleManager.LowCall1(t, "hasRole", newRole, roleAddress)
		assert.Equal(t, isGranted, true)

		list := roleManager.LowCall1(t, "getRoleList", newRole).([]common.Address)
		t.Log(list)
		t.Log(len(list))

		// renounceRole
		receipt = roleManager.Execute(t, roleKey, "renounceRole", newRole, roleAddress)

		logs = roleManager.FindLog(t, receipt.Logs, "RoleRevoked", false)

		assert.Equal(t, receipt.Status, uint64(1))

		copy(logRole[:], logs[0])
		assert.Equal(t, logRole, newRole)
		assert.Equal(t, common.BytesToAddress(logs[1]), roleAddress)
		assert.Equal(t, common.BytesToAddress(logs[2]), roleAddress)

		// verify
		isGranted = roleManager.LowCall1(t, "hasRole", newRole, roleAddress)
		assert.Equal(t, isGranted, false)

		list = roleManager.LowCall1(t, "getRoleList", newRole).([]common.Address)

		for _, e := range list {
			assert.NotEqual(t, e, roleAddress)
		}
		t.Log(list)
		t.Log(len(list))
	})

	/**
	*	case02: TestRenounceRole02_renounceNotEqualAddress
	*	- gen new account
	*	- gen new role name
	*	- grant role
	*	- check account has new role
	*	- renounce role with not equal address
	*	- check fail
	 */
	t.Run("TestRenounceRole02_renounceNotEqualAddress", func(t *testing.T) {
		client := DeployContract(t, common.Address{})
		roleManager := client.Contracts["RoleManager"]

		// gen key
		roleAddress, roleKey := backend.GenKeyWithFaucet(t, client, backend.ToWei(1))

		// new role name
		var newRole [32]byte
		copy(newRole[:], []byte("new minter role"))

		// non-admin account
		otherAddress, _ := backend.GenKey()

		// grant
		receipt := roleManager.Execute(t, nil, "grantRole", newRole, roleAddress)

		logs := roleManager.FindLog(t, receipt.Logs, "RoleGranted", false)

		assert.Equal(t, receipt.Status, uint64(1))

		var logRole [32]byte
		copy(logRole[:], logs[0])
		assert.Equal(t, logRole, newRole)
		assert.Equal(t, common.BytesToAddress(logs[1]), roleAddress)
		assert.Equal(t, common.BytesToAddress(logs[2]), client.Owner)

		// verify
		isGranted := roleManager.LowCall1(t, "hasRole", newRole, roleAddress)
		assert.Equal(t, isGranted, true)

		// renounceRole
		backend.ExpectedFail(t, roleManager, roleKey, "renounceRole", newRole, otherAddress)
	})
}

/**
*	TestSetRoleAdmin
*	Desc: test setRoleAdmin function
*	1. check setRoleAdmin successfully
*	2. check can not setRoleAdmin non-admin key
**/
func TestSetRoleAdmin(t *testing.T) {
	/**
	*	case01: TestSetRoleAdmin01_setRoleAdminSuccessfully
	*	- gen new account
	*	- gen new role name
	*	- grant role
	*	- gen new account
	*	- gen new role name
	*	- grant admin role
	*	- check account has new role
	*	- gen new account
	*	- setRoleAdmin successfully
	 */
	t.Run("TestSetRoleAdmin01_setRoleAdminSuccessfully", func(t *testing.T) {
		client := DeployContract(t, common.Address{})
		roleManager := client.Contracts["RoleManager"]

		// gen key
		roleAddress, _ := backend.GenKey()

		// new role name
		var newRole [32]byte
		copy(newRole[:], []byte("new minter role"))

		// grant
		receipt := roleManager.Execute(t, nil, "grantRole", newRole, roleAddress)

		logs := roleManager.FindLog(t, receipt.Logs, "RoleGranted", false)

		assert.Equal(t, receipt.Status, uint64(1))

		var logRole [32]byte
		copy(logRole[:], logs[0])
		assert.Equal(t, logRole, newRole)
		assert.Equal(t, common.BytesToAddress(logs[1]), roleAddress)
		assert.Equal(t, common.BytesToAddress(logs[2]), client.Owner)

		// new admin role
		var newAdminRole [32]byte
		copy(newAdminRole[:], []byte("new admin role"))

		// gen key
		newAdmin, _ := backend.GenKey()

		// grant
		backend.ExpectedSuccess(t, roleManager, nil, "grantRole", newAdminRole, newAdmin)

		// setRoleAdmin
		receipt = roleManager.Execute(t, nil, "setRoleAdmin", newRole, newAdminRole)

		logs = roleManager.FindLog(t, receipt.Logs, "RoleAdminChanged", false)

		assert.Equal(t, receipt.Status, uint64(1))

		copy(logRole[:], logs[0])
		assert.Equal(t, logRole, newRole)
		var log1 [32]byte
		var log2 [32]byte
		copy(log1[:], logs[1])
		copy(log2[:], logs[2])
		assert.Equal(t, log1, [32]byte{})
		assert.Equal(t, log2, newAdminRole)

		// verify
		adminRole := roleManager.LowCall1(t, "getRoleAdmin", newRole)
		assert.Equal(t, adminRole, newAdminRole)
	})

	/**
	*	case02: TestSetRoleAdmin02_setRoleAdminWithNonAdminRole
	*	- gen new account
	*	- gen new role name
	*	- grant role
	*	- check account has new role
	*	- setRoleAdmin with non-admin role
	*	- check fail
	 */
	t.Run("TestSetRoleAdmin02_setRoleAdminWithNonAdminRole", func(t *testing.T) {
		client := DeployContract(t, common.Address{})
		roleManager := client.Contracts["RoleManager"]

		// gen key
		roleAddress, _ := backend.GenKey()

		// new role name
		var newRole [32]byte
		copy(newRole[:], []byte("new minter role"))

		// grant
		receipt := roleManager.Execute(t, nil, "grantRole", newRole, roleAddress)

		logs := roleManager.FindLog(t, receipt.Logs, "RoleGranted", false)

		assert.Equal(t, receipt.Status, uint64(1))

		var logRole [32]byte
		copy(logRole[:], logs[0])
		assert.Equal(t, logRole, newRole)
		assert.Equal(t, common.BytesToAddress(logs[1]), roleAddress)
		assert.Equal(t, common.BytesToAddress(logs[2]), client.Owner)

		// new admin role
		var newAdminRole [32]byte
		copy(newAdminRole[:], []byte("new admin role"))

		// gen key
		newAdmin, _ := backend.GenKey()

		// grant
		backend.ExpectedSuccess(t, roleManager, nil, "grantRole", newAdminRole, newAdmin)

		// non-admin account
		_, nonAdminKey := backend.GenKeyWithFaucet(t, client, backend.ToWei(1))

		// setRoleAdmin
		backend.ExpectedFail(t, roleManager, nonAdminKey, "setRoleAdmin", newRole, newAdminRole)
	})
}
