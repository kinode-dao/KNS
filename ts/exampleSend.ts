// run a single op
// "yarn run runop [--network ...]"

import 'dotenv/config'
import hre, { ethers } from 'hardhat'
import { objdump } from './Utils'
import { AASigner, localUserOpSender, rpcUserOpSender } from './AASigner'
import { TestCounter__factory, EntryPoint__factory } from '../typechain'
import { parseEther } from 'ethers/lib/utils'
import { providers } from 'ethers'
import { TransactionReceipt } from '@ethersproject/abstract-provider/src.ts/index';

// eslint-disable-next-line @typescript-eslint/no-floating-promises
(async () => {

  const aa_rpc = process.env.RPC_OP

  const entrypointAddress     = process.env.AA_ENTRYPOINT
  const accountFactoryAddress = process.env.AA_SIMPLE_ACCOUNT_FACTORY

  const provider = new ethers.providers.JsonRpcProvider(aa_rpc)

  await provider.ready

  const eoaPriv = process.env.PRIVATE_KEY
  const eoaSigner = new ethers.Wallet(eoaPriv as any, provider)

  const eoaPub = await eoaSigner.getAddress()

  const eoaPubBalance = await provider.getBalance(eoaPub)

  const supportedEntryPoints: string[] = 
    await provider.send('eth_supportedEntryPoints', [])
      .then(ret => ret.map(ethers.utils.getAddress))
      .catch(err => console.log("wtf", err))

  if (!supportedEntryPoints.includes(entrypointAddress as string))
    console.error('ERROR: node', aa_rpc, 'does not support our EntryPoint')

  let sendUserOp = rpcUserOpSender(provider, entrypointAddress as string)

  const eoaAASigner = new AASigner(
    eoaSigner, 
    entrypointAddress as string, 
    sendUserOp, 
    accountFactoryAddress as string
  )

  const aaAddress = await eoaAASigner.getAddress()
  if (await provider.getBalance(aaAddress) < parseEther('0.01'))
    await eoaSigner.sendTransaction({ to: aaAddress, value: parseEther('0.01') })

  const entryPoint = EntryPoint__factory.connect(entrypointAddress as string, eoaSigner)
  let preDeposit = await entryPoint.balanceOf(aaAddress)

  if (preDeposit.lte(parseEther('0.005'))) {
    await entryPoint.depositTo(aaAddress, { value: parseEther('0.01') })
    preDeposit = await entryPoint.balanceOf(aaAddress)
  }

  const rcpt = await eoaAASigner.sendTransaction({ to: eoaPub, value: parseEther('0.0001') })

})()