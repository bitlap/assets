import 'asset_account.dart';

sealed class AssetFlatItem {
  const AssetFlatItem();
}

class SectionHeader extends AssetFlatItem {
  final AssetType type;
  final bool expanded;
  const SectionHeader(this.type, this.expanded);
}

class AssetCardItem extends AssetFlatItem {
  final AssetBase asset;
  const AssetCardItem(this.asset);
}
