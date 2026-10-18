using System.Globalization;
using OvoUi.Lang;

namespace Pollen.Localization;

public static class LocalizationService
{
    private static readonly ILangManager[] Managers =
    [
        AppLanguageManager.Instance
    ];

    public static IReadOnlyList<ILangManager> RegisteredManagers => Managers;

    public static CultureInfo CurrentCulture => AppLanguageManager.Instance.CurrentCulture;

    public static IObservable<string?> Welcome => AppLanguageManager.Instance.Welcome;

    public static void Initialize(CultureInfo? culture = null) =>
        SetCulture(culture ?? CultureInfo.CurrentUICulture);

    public static void SetCulture(CultureInfo culture)
    {
        ArgumentNullException.ThrowIfNull(culture);

        CultureInfo.CurrentCulture = culture;
        CultureInfo.CurrentUICulture = culture;

        foreach (var manager in Managers)
            manager.UpdateCulture(culture);
    }
}
