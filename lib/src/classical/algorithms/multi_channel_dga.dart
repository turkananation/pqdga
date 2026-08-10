import 'package:pqdga/src/classical/dga_core.dart';
import 'package:pqdga/src/common/multi_channel_codec.dart';

/// Multi-channel rendezvous label DGA (research generic, R8).
///
/// Same underlying stream is encoded for DNS **and** alternate channels
/// (DoH path token, HTTPS SNI-ish token, chat handle). **SOC lesson:** DNS
/// RPZ alone is insufficient — correlate alt-channel telemetry.
///
/// Difficulty: [config-seeded] (seed + channel set are IOCs).
class MultiChannelDGA extends DGAAlgorithm {
  /// Toy campaign id.
  final String campaignId;

  /// Channels to emit encodings for (see [MultiChannelCodec]).
  final List<String> channels;

  /// DNS TLD when `dns` channel is selected.
  final List<String> tld;

  /// Label / token length.
  final int tokenLength;

  /// Config seed mixed with date.
  final int seed;

  /// Charset for DNS LDH tokens.
  final String charset;

  const MultiChannelDGA({
    this.campaignId = 'toy-multichannel',
    this.channels = const [
      MultiChannelCodec.channelDns,
      MultiChannelCodec.channelDoh,
      MultiChannelCodec.channelHttps,
      MultiChannelCodec.channelChat,
    ],
    this.tld = const ['.com', '.net'],
    this.tokenLength = 12,
    this.seed = 0x4D43484E, // 'MCHN'
    this.charset = 'abcdefghijklmnopqrstuvwxyz0123456789',
  });
}
