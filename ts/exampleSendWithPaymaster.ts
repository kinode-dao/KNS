// run a single op
// "yarn run runop [--network ...]"

import 'dotenv/config'
import { ethers } from 'hardhat'
import { AASigner, rpcUserOpSender } from './AASigner'
import { EntryPoint__factory, VerifyingPaymaster__factory } from '../typechain'
import { parseEther } from 'ethers/lib/utils'
import { VPSigner } from './VerifyingPaymaster'

// eslint-disable-next-line @typescript-eslint/no-floating-promises
(async () => {

  const aa_url = process.env.RPC_OP

  const entrypointAddress         = process.env.AA_ENTRYPOINT
  const accountFactoryAddress     = process.env.AA_SIMPLE_ACCOUNT_FACTORY
  const verifyingPaymasterAddress = process.env.AA_VERIFYING_PAYMASTER

  const paymasterOwnerPriv  = process.env.AA_PAYMASTER_OWNER_PRIV

  const provider = new ethers.providers.JsonRpcProvider(aa_url)

  const eoaPriv = process.env.PRIVATE_KEY
  const eoaSigner = new ethers.Wallet(eoaPriv as any, provider)

  const paymasterOwnerSigner = new ethers.Wallet(paymasterOwnerPriv as any, provider)

  const paymasterPriv = process.env.PRIV_PAYMASTER
  const paymasterSigner = new ethers.Wallet(paymasterPriv as any, provider)

  const eoaPub = await eoaSigner.getAddress()

  const eoaPubBalance = await provider.getBalance(eoaPub)

  const supportedEntryPoints: string[] = 
    await provider.send('eth_supportedEntryPoints', [])
      .then(ret => ret.map(ethers.utils.getAddress))

  if (!supportedEntryPoints.includes(entrypointAddress as string))
    console.error('ERROR: node', aa_url, 'does not support our EntryPoint')

  let sendUserOp = rpcUserOpSender(provider, entrypointAddress as string)

  const eoaAASigner = new AASigner(
    eoaSigner, 
    entrypointAddress as string, 
    sendUserOp, 
    accountFactoryAddress as string,
    9999999999 // salt for create2 counterfactual address
  )

  const aaAddress = await eoaAASigner.getAddress()
  if (await provider.getBalance(aaAddress) < parseEther('0.01'))
    await eoaSigner.sendTransaction({ to: aaAddress, value: parseEther('0.01') })

  const verifyingPaymaster = VerifyingPaymaster__factory.connect(
    verifyingPaymasterAddress as string, 
    paymasterOwnerSigner
  )

  const vpSigner = new VPSigner(
    paymasterSigner,
    verifyingPaymasterAddress as string
  )

  const entryPoint = EntryPoint__factory.connect(entrypointAddress as string, eoaSigner)

  if (await entryPoint.balanceOf(verifyingPaymasterAddress!) < parseEther('0.1'))
    await verifyingPaymaster.addStake(86400, { value: parseEther('0.1') })

  const rcpt = await eoaAASigner.sendTransaction(
    { to: eoaPub, value: parseEther('0.0001') },
    vpSigner
  )

})()