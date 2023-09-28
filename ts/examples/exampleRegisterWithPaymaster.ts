import 'dotenv/config'
import { ethers } from 'hardhat'
import { AASigner, rpcUserOpSender } from '../AASigner'
import { UqNFT__factory, EntryPoint__factory, VerifyingPaymaster__factory } from '../../typechain'
import { arrayify, parseEther } from 'ethers/lib/utils'
import { VPSigner } from "../VerifyingPaymaster"

// eslint-disable-next-line @typescript-eslint/no-floating-promises
(async () => {

  const aa_url = process.env.RPC_OP

  const provider = new ethers.providers.JsonRpcProvider(aa_url)

  const entrypointAddress = process.env.AA_ENTRYPOINT
  const accountFactoryAddress = process.env.AA_SIMPLE_ACCOUNT_FACTORY
  const verifyingPaymasterAddress = process.env.AA_VERIFYING_PAYMASTER

  const paymasterOwnerPriv = process.env.AA_PAYMASTER_OWNER_PRIV

  const eoaPriv = process.env.PRIVATE_KEY
  const eoaSigner = new ethers.Wallet(eoaPriv as any, provider)

  const paymsaterOwnerSigner = new ethers.Wallet(paymasterOwnerPriv as any, provider)

  const paymasterPriv = process.env.PRIV_PAYMASTER
  const paymasterSigner = new ethers.Wallet(paymasterPriv as any, provider)

  let sendUserOp = rpcUserOpSender(provider, entrypointAddress as string)

  const eoaAASigner = new AASigner(
    eoaSigner,
    entrypointAddress as string,
    sendUserOp,
    accountFactoryAddress as string,
    111199
  )

  const aaAddress = await eoaAASigner.getAddress()

  // if (await provider.getBalance(aaAddress) < parseEther('0.01'))
  //   await eoaSigner.sendTransaction({ to: aaAddress, value: parseEther('0.01') })

  const verifyingPaymaster = VerifyingPaymaster__factory.connect(
    verifyingPaymasterAddress as string,
    paymsaterOwnerSigner
  )

  const entryPoint = EntryPoint__factory.connect(entrypointAddress as string, eoaSigner)

  const vpSigner = new VPSigner(
    paymasterSigner,
    verifyingPaymasterAddress as string
  )

  const paymasterBal = await entryPoint.balanceOf(verifyingPaymasterAddress as string)
  if (paymasterBal < parseEther('0.01'))
    await entryPoint.depositTo(verifyingPaymasterAddress as string, { value: (parseEther('.01').sub(paymasterBal)) })
  
  const uqNFT = UqNFT__factory.connect(process.env.UQNFT as string, eoaAASigner)

  const name = domainToDNSWireFormat('dlls.uq').toString('hex')
  const data = await uqNFT.populateTransaction.register(
    arrayify('0x'+name), aaAddress
  )

  const rcpt = await eoaAASigner.sendTransaction(
    { to: uqNFT.address, data: data.data },
    // { to: aaAddress },
    vpSigner
  )

})()

function domainToDNSWireFormat(domain: string): Buffer {
  const parts = domain.split('.');
  const result = [];
  for (const part of parts) {
    result.push(part.length);
    result.push(...Buffer.from(part));
  }
  result.push(0); // null byte to end the domain name
  return Buffer.from(result);
}
