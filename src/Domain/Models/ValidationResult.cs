using System.Collections.Generic;

namespace FnCast.Domain.Models
{
    /// <summary>
    /// Represents the outcome of validating an inbound event payload.
    /// </summary>
    public sealed class ValidationResult
    {
        /// <summary>
        /// Gets a value indicating whether the payload is valid.
        /// </summary>
        public bool IsValid { get; }

        /// <summary>
        /// Gets any validation error messages.
        /// </summary>
        public IReadOnlyList<string> Errors { get; }

        /// <summary>
        /// Initializes a new instance of the <see cref="ValidationResult"/> class.
        /// </summary>
        /// <param name="isValid">Whether the payload is valid.</param>
        /// <param name="errors">Optional list of errors.</param>
        public ValidationResult(bool isValid, IReadOnlyList<string>? errors = null)
        {
            IsValid = isValid;
            Errors = errors ?? new List<string>();
        }

        /// <summary>
        /// Creates a success result.
        /// </summary>
        public static ValidationResult Success() => new(true);

        /// <summary>
        /// Creates a failure result from error messages.
        /// </summary>
        public static ValidationResult Failure(params string[] errors) => new(false, errors);
    }
}
