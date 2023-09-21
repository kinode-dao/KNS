// run a single op
// "yarn run runop [--network ...]"

import 'dotenv/config'
import hre, { ethers } from 'hardhat'
import { AASigner, rpcUserOpSender } from './AASigner'
import { VerifyingPaymaster__factory } from '../typechain'
import { arrayify, defaultAbiCoder, hexConcat, parseEther } from 'ethers/lib/utils'
import { providers } from 'ethers'
import { TransactionReceipt } from '@ethersproject/abstract-provider/src.ts/index';
import { VPSigner } from './VerifyingPaymaster'

// eslint-disable-next-line @typescript-eslint/no-floating-promises
(async () => {

  const aa_url = process.env.RPC_OP

  const entrypointAddress         = process.env.AA_ENTRYPOINT
  const accountFactoryAddress     = process.env.AA_SIMPLE_ACCOUNT_FACTORY
  const verifyingPaymasterAddress = process.env.AA_VERIFYING_PAYMASTER

  const provider = new ethers.providers.JsonRpcProvider(aa_url)

  const eoaPriv = process.env.PRIVATE_KEY
  const eoaSigner = new ethers.Wallet(eoaPriv as any, provider)

  const paymasterPriv = process.env.PRIV_PAYMASTER
  const paymasterSigner = new ethers.Wallet(paymasterPriv as any, provider)

  const eoaPub = await eoaSigner.getAddress()

  console.log("eoaPub", eoaPub)

  const eoaPubBalance = await provider.getBalance(eoaPub)

  console.log("eoaPubBalance", eoaPubBalance)

  const newprovider = new providers.JsonRpcProvider(aa_url)

  const supportedEntryPoints: string[] = 
    await newprovider.send('eth_supportedEntryPoints', [])
      .then(ret => ret.map(ethers.utils.getAddress))

  if (!supportedEntryPoints.includes(entrypointAddress as string))
    console.error('ERROR: node', aa_url, 'does not support our EntryPoint')

  let sendUserOp = rpcUserOpSender(newprovider, entrypointAddress as string)

  const eoaAASigner = new AASigner(
    eoaSigner, 
    entrypointAddress as string, 
    sendUserOp, 
    accountFactoryAddress as string,
    1 // salt for create2 counterfactual address
  )

  const aaAddress = await eoaAASigner.getAddress()

  const verifyingPaymaster = VerifyingPaymaster__factory.connect(
    verifyingPaymasterAddress as string, 
    paymasterSigner
  )

  const vpSigner = new VPSigner(
    paymasterSigner,
    verifyingPaymasterAddress as string
  )

  console.log("timestamp", (await provider.getBlock('latest')).timestamp)
  // const entryPoint = EntryPoint__factory.connect(entrypointAddress as string, eoaSigner)
  // let preDeposit = await entryPoint.balanceOf(aaAddress)

  // if (preDeposit.lte(parseEther('0.005'))) {
  //   await entryPoint.depositTo(aaAddress, { value: parseEther('0.01') })
  //   preDeposit = await entryPoint.balanceOf(aaAddress)
  // }


  const rcpt = await eoaAASigner.sendTransaction(
    { to: eoaPub, value: parseEther('0.0001') },
    vpSigner
  )

})()