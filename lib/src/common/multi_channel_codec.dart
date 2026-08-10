/// Encode the same rendezvous token for DNS and alternate channels (R8).
///
/// Lab/research only — tokens are synthetic, never live C2 handles.
class MultiChannelCodec {
  static const String channelDns = 'dns';
  static const String channelDoh = 'doh';
  static const String channelHttps = 'https';
  static const String channelChat = 'chat';

  /// All supported channel ids.
  static const List<String> allChannels = [
    channelDns,
    channelDoh,
    channelHttps,
    channelChat,
  ];

  /// Encode [token] for [channel]. [tld] used only for DNS FQDN form.
  static String encode(
    String token, {
    required String channel,
    String tld = '.com',
  }) {
    final t = token.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final safeTld = tld.startsWith('.') ? tld : '.$tld';
    switch (channel) {
      case channelDns:
        return '$t$safeTld';
      case channelDoh:
        return 'doh://resolver.lab/dns-query?name=$t$safeTld';
      case channelHttps:
        return 'https://$t$safeTld/';
      case channelChat:
        return '@pqdga_$t';
      default:
        throw ArgumentError(
          'unknown channel "$channel"; use one of $allChannels',
        );
    }
  }

  /// Encode [token] for every channel in [channels].
  static Map<String, String> encodeAll(
    String token, {
    List<String> channels = allChannels,
    String tld = '.com',
  }) {
    final out = <String, String>{};
    for (final c in channels) {
      out[c] = encode(token, channel: c, tld: tld);
    }
    return out;
  }
}
