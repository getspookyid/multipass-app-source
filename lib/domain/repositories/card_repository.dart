abstract class CardRepository {
  Future<void> connect();
  Future<bool> authenticate();
  Future<String> getPublicAddress();
  Future<void> disconnect();
}
