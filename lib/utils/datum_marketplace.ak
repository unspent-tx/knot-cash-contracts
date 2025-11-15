use cardano/address.{Address}

pub type MarketplaceDatum {
  MarketplaceDatum {
    seller: Address,
    price: Int,
    policy: ByteArray,
    tokenName: ByteArray,
  }
}
