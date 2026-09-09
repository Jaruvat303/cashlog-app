import '../../transactions/domain/transaction.dart';

/// Success-shaped result of one `POST /upload-slip` call — `failed` is
/// deliberately not a third variant here, it stays a `Left(Failure)` from
/// `SlipUploadRepository.uploadOne` (CLAUDE.md: repository methods always
/// return `Either<Failure, T>`, never fold failure into a success type).
///
/// [SlipDuplicate] covers both real-world duplicate paths confirmed against
/// cashlog-api: the common case (`transaction_usecase.go`'s Redis
/// short-circuit — HTTP 200, `success:true`, no `data` key at all) and the
/// rarer DB-constraint race (`DUPLICATE_RESOURCE`, HTTP 409). Both mean the
/// same thing to this app: the file was already processed, no new
/// transaction to write.
sealed class SlipUploadOutcome {
  const SlipUploadOutcome();
}

final class SlipUploaded extends SlipUploadOutcome {
  const SlipUploaded(this.transaction);
  final Transaction transaction;
}

final class SlipDuplicate extends SlipUploadOutcome {
  const SlipDuplicate();
}
