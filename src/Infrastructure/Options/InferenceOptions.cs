namespace FnCast.Infrastructure.Options
{
    /// <summary>
    /// Configuration options for placeholder inference behavior.
    /// </summary>
    public sealed class InferenceOptions
    {
        /// <summary>
        /// Gets or sets the inference mode used by the placeholder executor.
        /// </summary>
        public InferenceMode Mode { get; set; } = InferenceMode.Uppercase;
    }

    /// <summary>
    /// Defines modes for the placeholder inference executor.
    /// </summary>
    public enum InferenceMode
    {
        Uppercase,
        Lowercase,
        Echo
    }
}
