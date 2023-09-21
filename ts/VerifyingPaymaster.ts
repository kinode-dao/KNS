import { Bytes, Signer } from 'ethers'
import { Deferrable } from '@ethersproject/properties'
import { Provider, TransactionRequest } from '@ethersproject/providers'
import { 
    VerifyingPaymaster,
    VerifyingPaymaster__factory 
} from '../typechain'
import { UserOperation } from "./UserOperation"
import { arrayify, defaultAbiCoder, hexConcat } from 'ethers/lib/utils'

export class VPSigner extends Signer {
    private readonly verifyingPaymaster: VerifyingPaymaster

    constructor (
        readonly signer: Signer,
        readonly verifyingPaymasterAddress: string,
        readonly provider = signer.provider
    ) {
        super()
        this.verifyingPaymaster = VerifyingPaymaster__factory
            .connect(verifyingPaymasterAddress, signer)
    }

    async includePaymaster (op: UserOperation): Promise<UserOperation> {

        const block = await this.provider?.getBlock('latest')
        const timestamp = block?.timestamp
        const validFrom = timestamp as number
        const validTo   = timestamp as number + 20000

        const hash = await this.verifyingPaymaster
            .getHash(op, validTo, validFrom)

        const sig = await this.signer.signMessage(arrayify(hash))

        op.paymasterAndData = hexConcat([
            this.verifyingPaymaster.address,
            defaultAbiCoder.encode(['uint48', 'uint48'], [validTo, validFrom]),
            sig
        ])

        return op

    }

    async getAddress(): Promise<string> {
        return this.signer.getAddress();
    }

    async signMessage (_message: Bytes | string): Promise<string> {
        throw new Error('signMessage: unsupported by VerifyingPaymaster')
    }

    async signTransaction (_transaction: Deferrable<TransactionRequest>): Promise<string> {
        throw new Error('signMessage: unsupported by VerifyingPaymaster')
    }

    connect (_provider: Provider): Signer {
        throw new Error('connect not implemented')
    }

}