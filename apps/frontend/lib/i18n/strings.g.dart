/// Generated file. Do not edit.
///
/// Original: lib/i18n
/// To regenerate, run: `dart run slang`
///
/// Locales: 2
/// Strings: 208 (104 per locale)
///
/// Built on 2026-02-27 at 19:55 UTC

// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang_flutter/slang_flutter.dart';
export 'package:slang_flutter/slang_flutter.dart';

const AppLocale _baseLocale = AppLocale.uk;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.uk) // set locale
/// - Locale locale = AppLocale.uk.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.uk) // locale check
enum AppLocale with BaseAppLocale<AppLocale, Translations> {
	uk(languageCode: 'uk', build: Translations.build),
	en(languageCode: 'en', build: _StringsEn.build);

	const AppLocale({required this.languageCode, this.scriptCode, this.countryCode, required this.build}); // ignore: unused_element

	@override final String languageCode;
	@override final String? scriptCode;
	@override final String? countryCode;
	@override final TranslationBuilder<AppLocale, Translations> build;

	/// Gets current instance managed by [LocaleSettings].
	Translations get translations => LocaleSettings.instance.translationMap[this]!;
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of t).
/// Configurable via 'translate_var'.
///
/// Usage:
/// String a = t.someKey.anotherKey;
/// String b = t['someKey.anotherKey']; // Only for edge cases!
Translations get t => LocaleSettings.instance.currentTranslations;

/// Method B: Advanced
///
/// All widgets using this method will trigger a rebuild when locale changes.
/// Use this if you have e.g. a settings page where the user can select the locale during runtime.
///
/// Step 1:
/// wrap your App with
/// TranslationProvider(
/// 	child: MyApp()
/// );
///
/// Step 2:
/// final t = Translations.of(context); // Get t variable.
/// String a = t.someKey.anotherKey; // Use t variable.
/// String b = t['someKey.anotherKey']; // Only for edge cases!
class TranslationProvider extends BaseTranslationProvider<AppLocale, Translations> {
	TranslationProvider({required super.child}) : super(settings: LocaleSettings.instance);

	static InheritedLocaleData<AppLocale, Translations> of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context);
}

/// Method B shorthand via [BuildContext] extension method.
/// Configurable via 'translate_var'.
///
/// Usage (e.g. in a widget's build method):
/// context.t.someKey.anotherKey
extension BuildContextTranslationsExtension on BuildContext {
	Translations get t => TranslationProvider.of(this).translations;
}

/// Manages all translation instances and the current locale
class LocaleSettings extends BaseFlutterLocaleSettings<AppLocale, Translations> {
	LocaleSettings._() : super(utils: AppLocaleUtils.instance);

	static final instance = LocaleSettings._();

	// static aliases (checkout base methods for documentation)
	static AppLocale get currentLocale => instance.currentLocale;
	static Stream<AppLocale> getLocaleStream() => instance.getLocaleStream();
	static AppLocale setLocale(AppLocale locale, {bool? listenToDeviceLocale = false}) => instance.setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale setLocaleRaw(String rawLocale, {bool? listenToDeviceLocale = false}) => instance.setLocaleRaw(rawLocale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale useDeviceLocale() => instance.useDeviceLocale();
	@Deprecated('Use [AppLocaleUtils.supportedLocales]') static List<Locale> get supportedLocales => instance.supportedLocales;
	@Deprecated('Use [AppLocaleUtils.supportedLocalesRaw]') static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
	static void setPluralResolver({String? language, AppLocale? locale, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) => instance.setPluralResolver(
		language: language,
		locale: locale,
		cardinalResolver: cardinalResolver,
		ordinalResolver: ordinalResolver,
	);
}

/// Provides utility functions without any side effects.
class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale, Translations> {
	AppLocaleUtils._() : super(baseLocale: _baseLocale, locales: AppLocale.values);

	static final instance = AppLocaleUtils._();

	// static aliases (checkout base methods for documentation)
	static AppLocale parse(String rawLocale) => instance.parse(rawLocale);
	static AppLocale parseLocaleParts({required String languageCode, String? scriptCode, String? countryCode}) => instance.parseLocaleParts(languageCode: languageCode, scriptCode: scriptCode, countryCode: countryCode);
	static AppLocale findDeviceLocale() => instance.findDeviceLocale();
	static List<Locale> get supportedLocales => instance.supportedLocales;
	static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}

// translations

// Path: <root>
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.uk,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <uk>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	// Translations
	late final _StringsCommonUk common = _StringsCommonUk._(_root);
	late final _StringsAnalyzeUk analyze = _StringsAnalyzeUk._(_root);
	late final _StringsChatUk chat = _StringsChatUk._(_root);
	late final _StringsPromptUk prompt = _StringsPromptUk._(_root);
	late final _StringsPasteUk paste = _StringsPasteUk._(_root);
	late final _StringsGeminiStepUk geminiStep = _StringsGeminiStepUk._(_root);
	late final _StringsReviewUk review = _StringsReviewUk._(_root);
	late final _StringsProcessingUk processing = _StringsProcessingUk._(_root);
	late final _StringsResultsUk results = _StringsResultsUk._(_root);
}

// Path: common
class _StringsCommonUk {
	_StringsCommonUk._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get copyLogs => 'Копіювати логи';
	String get logsCopied => 'Логи скопійовано! Вставте їх в AI для діагностики.';
	String get back => 'Назад';
	String get done => 'Готово!';
	String get error => 'Помилка';
	String get analyzing => 'Аналіз...';
	String get analyze => 'Аналізувати';
	String get loading => 'Завантаження...';
	String get cancel => 'Скасувати';
	String get refresh => 'Оновити';
	String get toggleDark => 'Темна тема';
	String get toggleLight => 'Світла тема';
	String get paste => 'Вставити';
}

// Path: analyze
class _StringsAnalyzeUk {
	_StringsAnalyzeUk._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Funny Threads AI';
	String get subtitle => 'Перетворюйте YouTube відео на віральні кліпи';
	String get urlLabel => 'YouTube URL';
	String get urlHint => 'https://www.youtube.com/watch?v=...';
	String get languageLabel => 'Профіль мови';
	late final _StringsAnalyzeLanguagesUk languages = _StringsAnalyzeLanguagesUk._(_root);
}

// Path: chat
class _StringsChatUk {
	_StringsChatUk._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Funny Threads AI';
	String get welcomeMessage => 'Привіт! Я допоможу перетворити YouTube відео на віральні кліпи. Надішліть мені посилання на відео.';
	String get selectLanguagePrompt => 'Яку мову використовувати для аналізу?';
	String get thinking => 'Думаю...';
	String get analyzingVideo => 'Аналізую відео...';
	String get videoFound => 'Знайшов відео! Виберіть мову для генерації:';
	String get buildingPrompt => 'Готую AI промпт...';
	String get promptReady => 'Промпт готовий! Скопіюйте його та відкрийте ваш AI-інструмент.';
	String get promptCopied => 'Промпт скопійовано!';
	String get pasteJsonPrompt => 'Вставте JSON відповідь від AI:';
	String get validating => 'Перевіряю відповідь...';
	String get validationSuccess => 'Чудово! Знайдено {count} моментів. Переходжу до огляду...';
	String get validationFailed => 'Помилка валідації. Перевірте формат JSON.';
	String get retry => 'Спробувати ще раз';
	String get resetConfirm => 'Почати спочатку? Весь прогрес буде втрачено.';
	String get aiPromptTitle => 'AI Промпт';
	String get aiPromptSubtitle => 'Скопіюйте та вставте в ChatGPT, Claude або Gemini';
	String get copyPrompt => 'Копіювати';
	String get openAiTool => 'Відкрити AI';
	String get openChatGPT => 'Відкрити ChatGPT';
	String get openClaude => 'Відкрити Claude';
	String get iHaveResponse => 'Вже маю відповідь';
	String get send => 'Надіслати';
	String get proceed => 'Продовжити';
	String get urlHint => 'https://youtube.com/watch?v=...';
	String get jsonHint => 'Вставте JSON відповідь тут...';
	String get errorNetwork => 'Помилка мережі. Перевірте з\'єднання.';
	String get errorInvalidUrl => 'Невірне посилання на YouTube.';
	String get errorNoTranscript => 'Субтитри не знайдено. Спробуйте інше відео.';
}

// Path: prompt
class _StringsPromptUk {
	_StringsPromptUk._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Копіювати AI промпт';
	String get step1 => '1. Скопіюйте промпт нижче';
	String get step2 => '2. Вставте його в ChatGPT, Claude, Gemini тощо.';
	String get copyPrompt => 'Скопіювати промпт';
	String get copied => 'Скопійовано!';
	String get nextStep => 'У мене є відповідь AI — Вставити JSON';
}

// Path: paste
class _StringsPasteUk {
	_StringsPasteUk._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Вставити відповідь AI';
	String get subtitle => 'Вставте JSON-відповідь від вашого AI-інструменту';
	String get hint => '{\n  "videoTitle": "...",\n  "moments": [...]\n}';
	String get validate => 'Перевірити та переглянути моменти';
}

// Path: geminiStep
class _StringsGeminiStepUk {
	_StringsGeminiStepUk._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Запитати Gemini';
	String get step1Title => '1. Скопіювати та відкрити Gemini';
	String get step1Hint => 'Промпт скопіюється в буфер. Вставте його в Gemini та попросіть смішні моменти.';
	String get copyOpen => 'Скопіювати та відкрити Gemini';
	String get copiedLabel => 'Промпт скопійовано';
	String get step2Title => '2. Вставити відповідь Gemini';
	String get step2Hint => 'Поверніться сюди та вставте JSON відповідь нижче';
	String get validate => 'Перевірити та переглянути моменти';
}

// Path: review
class _StringsReviewUk {
	_StringsReviewUk._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Огляд моментів';
	String get selectAll => 'Вибрати все';
	String get deselectAll => 'Скасувати вибір';
	String get noMoments => 'У відповіді AI не знайдено моментів.\nПоверніться та згенеруйте заново, коли з\'являться субтитри.';
	String get minSelectionError => 'Виберіть принаймні 3 моменти для генерації.';
	String get clipDuration => '{duration}с кліп';
	String get selectedInfo => '{selected} з {total} вибрано';
	String get generate => 'Згенерувати {count} кліпів';
	String get generateDisabled => 'Виберіть моменти для генерації';
	String get tapToLoadPreview => 'Натисніть, щоб завантажити прев\'ю';
	String get selectMoment => 'Вибрати момент';
	String get deselectMoment => 'Скасувати вибір моменту';
	String get selected => 'Вибрано';
	String get showMore => 'Показати більше';
	String get showLess => 'Показати менше';
}

// Path: processing
class _StringsProcessingUk {
	_StringsProcessingUk._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Генерація кліпів';
	String get errorTitle => 'Щось пішло не так';
	String get goBack => 'Повернутися до огляду';
	String get submitting => 'Надсилання завдання...';
	String get fetchingInfo => 'Отримання інформації про відео...';
	String get downloading => 'Завантаження відео...';
	String get cutting => 'Нарізка кліпів...';
	String get disclaimer => 'Завантаження та нарізка вибраних моментів.\nЦе може зайняти кілька хвилин залежно від довжини відео.';
}

// Path: results
class _StringsResultsUk {
	_StringsResultsUk._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Ваші кліпи';
	String get startOver => 'Почати заново';
	String get noClips => 'Кліпи не були згенеровані.';
	String get tapToPreview => 'Натисніть для перегляду';
	String get clipsReady => '{count} кліпів готово';
	String get downloadHint => 'Завантаження відкривається в новій вкладці для сумісності з iPhone Safari.';
	String get downloadBlocked => 'Завантаження заблоковане браузером. Дозвольте pop-up і повторіть.';
	String get playerLoadFailed => 'Не вдалося завантажити прев\'ю. Спробуйте ще раз.';
	String get copyPostText => 'Копіювати текст поста';
	String get postTextCopied => 'Текст поста скопійовано!';
	String get preview => 'Перегляд';
	String get download => 'Завантажити';
}

// Path: analyze.languages
class _StringsAnalyzeLanguagesUk {
	_StringsAnalyzeLanguagesUk._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get en => 'Англійська';
	String get uk => 'Українська';
	String get uk_18 => 'Українська 18+';
	String get ru => 'Російська';
}

// Path: <root>
class _StringsEn implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsEn.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	@override late final _StringsEn _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsCommonEn common = _StringsCommonEn._(_root);
	@override late final _StringsAnalyzeEn analyze = _StringsAnalyzeEn._(_root);
	@override late final _StringsChatEn chat = _StringsChatEn._(_root);
	@override late final _StringsPromptEn prompt = _StringsPromptEn._(_root);
	@override late final _StringsPasteEn paste = _StringsPasteEn._(_root);
	@override late final _StringsGeminiStepEn geminiStep = _StringsGeminiStepEn._(_root);
	@override late final _StringsReviewEn review = _StringsReviewEn._(_root);
	@override late final _StringsProcessingEn processing = _StringsProcessingEn._(_root);
	@override late final _StringsResultsEn results = _StringsResultsEn._(_root);
}

// Path: common
class _StringsCommonEn implements _StringsCommonUk {
	_StringsCommonEn._(this._root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get copyLogs => 'Copy logs';
	@override String get logsCopied => 'Logs copied! Paste to AI to diagnose.';
	@override String get back => 'Back';
	@override String get done => 'Done!';
	@override String get error => 'Error';
	@override String get analyzing => 'Analyzing...';
	@override String get analyze => 'Analyze';
	@override String get loading => 'Loading...';
	@override String get cancel => 'Cancel';
	@override String get refresh => 'Refresh';
	@override String get toggleDark => 'Dark Theme';
	@override String get toggleLight => 'Light Theme';
	@override String get paste => 'Paste';
}

// Path: analyze
class _StringsAnalyzeEn implements _StringsAnalyzeUk {
	_StringsAnalyzeEn._(this._root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Funny Threads AI';
	@override String get subtitle => 'Turn a YouTube video into viral clips';
	@override String get urlLabel => 'YouTube URL';
	@override String get urlHint => 'https://www.youtube.com/watch?v=...';
	@override String get languageLabel => 'Language profile';
	@override late final _StringsAnalyzeLanguagesEn languages = _StringsAnalyzeLanguagesEn._(_root);
}

// Path: chat
class _StringsChatEn implements _StringsChatUk {
	_StringsChatEn._(this._root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Funny Threads AI';
	@override String get welcomeMessage => 'Hi! I\'ll help you turn YouTube videos into viral clips. Send me a video link.';
	@override String get selectLanguagePrompt => 'Which language should I use for the analysis?';
	@override String get thinking => 'Thinking...';
	@override String get analyzingVideo => 'Analyzing video...';
	@override String get videoFound => 'Found the video! Select a language for generation:';
	@override String get buildingPrompt => 'Preparing AI prompt...';
	@override String get promptReady => 'Prompt ready! Copy it and open your AI tool.';
	@override String get promptCopied => 'Prompt copied!';
	@override String get pasteJsonPrompt => 'Paste the AI JSON response:';
	@override String get validating => 'Validating response...';
	@override String get validationSuccess => 'Great! Found {count} moments. Going to review...';
	@override String get validationFailed => 'Validation error. Please check the JSON format.';
	@override String get retry => 'Try again';
	@override String get resetConfirm => 'Start over? All progress will be lost.';
	@override String get aiPromptTitle => 'AI Prompt';
	@override String get aiPromptSubtitle => 'Copy and paste into ChatGPT, Claude, or Gemini';
	@override String get copyPrompt => 'Copy';
	@override String get openAiTool => 'Open AI Tool';
	@override String get openChatGPT => 'Open ChatGPT';
	@override String get openClaude => 'Open Claude';
	@override String get iHaveResponse => 'I have a response';
	@override String get send => 'Send';
	@override String get proceed => 'Continue';
	@override String get urlHint => 'https://youtube.com/watch?v=...';
	@override String get jsonHint => 'Paste JSON response here...';
	@override String get errorNetwork => 'Network error. Please check your connection.';
	@override String get errorInvalidUrl => 'Invalid YouTube link.';
	@override String get errorNoTranscript => 'Subtitles not found. Try another video.';
}

// Path: prompt
class _StringsPromptEn implements _StringsPromptUk {
	_StringsPromptEn._(this._root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Copy AI Prompt';
	@override String get step1 => '1. Copy the prompt below';
	@override String get step2 => '2. Paste it into ChatGPT, Claude, Gemini, etc.';
	@override String get copyPrompt => 'Copy Prompt';
	@override String get copied => 'Copied!';
	@override String get nextStep => 'I\'ve got the AI response — Paste JSON';
}

// Path: paste
class _StringsPasteEn implements _StringsPasteUk {
	_StringsPasteEn._(this._root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Paste AI Response';
	@override String get subtitle => 'Paste the JSON response from your AI tool';
	@override String get hint => '{\n  "videoTitle": "...",\n  "moments": [...]\n}';
	@override String get validate => 'Validate & Preview Moments';
}

// Path: geminiStep
class _StringsGeminiStepEn implements _StringsGeminiStepUk {
	_StringsGeminiStepEn._(this._root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ask Gemini';
	@override String get step1Title => '1. Copy & Open Gemini';
	@override String get step1Hint => 'The prompt will be copied to clipboard. Paste it in Gemini and ask for funny moments.';
	@override String get copyOpen => 'Copy & Open Gemini';
	@override String get copiedLabel => 'Prompt copied!';
	@override String get step2Title => '2. Paste Gemini\'s response';
	@override String get step2Hint => 'Come back here and paste the JSON response below';
	@override String get validate => 'Validate & Preview Moments';
}

// Path: review
class _StringsReviewEn implements _StringsReviewUk {
	_StringsReviewEn._(this._root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Review Moments';
	@override String get selectAll => 'Select All';
	@override String get deselectAll => 'Deselect All';
	@override String get noMoments => 'No moments found in AI response.\nGo back and regenerate after transcript is available.';
	@override String get minSelectionError => 'Select at least 3 moments to generate.';
	@override String get clipDuration => '{duration}s clip';
	@override String get selectedInfo => '{selected} of {total} selected';
	@override String get generate => 'Generate {count} Video Posts';
	@override String get generateDisabled => 'Select moments to generate posts';
	@override String get tapToLoadPreview => 'Tap to load preview';
	@override String get selectMoment => 'Select moment';
	@override String get deselectMoment => 'Deselect moment';
	@override String get selected => 'Selected';
	@override String get showMore => 'Show more';
	@override String get showLess => 'Show less';
}

// Path: processing
class _StringsProcessingEn implements _StringsProcessingUk {
	_StringsProcessingEn._(this._root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Generating Clips';
	@override String get errorTitle => 'Something went wrong';
	@override String get goBack => 'Go back to review';
	@override String get submitting => 'Submitting job...';
	@override String get fetchingInfo => 'Fetching video info...';
	@override String get downloading => 'Downloading video...';
	@override String get cutting => 'Cutting clips...';
	@override String get disclaimer => 'Downloading and cutting your selected moments.\nThis may take a few minutes depending on video length.';
}

// Path: results
class _StringsResultsEn implements _StringsResultsUk {
	_StringsResultsEn._(this._root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Your Clips';
	@override String get startOver => 'Start over';
	@override String get noClips => 'No clips were generated.';
	@override String get tapToPreview => 'Tap to preview';
	@override String get clipsReady => '{count} clips ready';
	@override String get downloadHint => 'Downloads open in a new tab for iPhone Safari compatibility.';
	@override String get downloadBlocked => 'Download blocked by browser. Allow pop-ups and try again.';
	@override String get playerLoadFailed => 'Unable to load preview. Try again.';
	@override String get copyPostText => 'Copy post text';
	@override String get postTextCopied => 'Post text copied!';
	@override String get preview => 'Preview';
	@override String get download => 'Download';
}

// Path: analyze.languages
class _StringsAnalyzeLanguagesEn implements _StringsAnalyzeLanguagesUk {
	_StringsAnalyzeLanguagesEn._(this._root);

	@override final _StringsEn _root; // ignore: unused_field

	// Translations
	@override String get en => 'English';
	@override String get uk => 'Ukrainian';
	@override String get uk_18 => 'Ukrainian 18+';
	@override String get ru => 'Russian';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'common.copyLogs': return 'Копіювати логи';
			case 'common.logsCopied': return 'Логи скопійовано! Вставте їх в AI для діагностики.';
			case 'common.back': return 'Назад';
			case 'common.done': return 'Готово!';
			case 'common.error': return 'Помилка';
			case 'common.analyzing': return 'Аналіз...';
			case 'common.analyze': return 'Аналізувати';
			case 'common.loading': return 'Завантаження...';
			case 'common.cancel': return 'Скасувати';
			case 'common.refresh': return 'Оновити';
			case 'common.toggleDark': return 'Темна тема';
			case 'common.toggleLight': return 'Світла тема';
			case 'common.paste': return 'Вставити';
			case 'analyze.title': return 'Funny Threads AI';
			case 'analyze.subtitle': return 'Перетворюйте YouTube відео на віральні кліпи';
			case 'analyze.urlLabel': return 'YouTube URL';
			case 'analyze.urlHint': return 'https://www.youtube.com/watch?v=...';
			case 'analyze.languageLabel': return 'Профіль мови';
			case 'analyze.languages.en': return 'Англійська';
			case 'analyze.languages.uk': return 'Українська';
			case 'analyze.languages.uk_18': return 'Українська 18+';
			case 'analyze.languages.ru': return 'Російська';
			case 'chat.title': return 'Funny Threads AI';
			case 'chat.welcomeMessage': return 'Привіт! Я допоможу перетворити YouTube відео на віральні кліпи. Надішліть мені посилання на відео.';
			case 'chat.selectLanguagePrompt': return 'Яку мову використовувати для аналізу?';
			case 'chat.thinking': return 'Думаю...';
			case 'chat.analyzingVideo': return 'Аналізую відео...';
			case 'chat.videoFound': return 'Знайшов відео! Виберіть мову для генерації:';
			case 'chat.buildingPrompt': return 'Готую AI промпт...';
			case 'chat.promptReady': return 'Промпт готовий! Скопіюйте його та відкрийте ваш AI-інструмент.';
			case 'chat.promptCopied': return 'Промпт скопійовано!';
			case 'chat.pasteJsonPrompt': return 'Вставте JSON відповідь від AI:';
			case 'chat.validating': return 'Перевіряю відповідь...';
			case 'chat.validationSuccess': return 'Чудово! Знайдено {count} моментів. Переходжу до огляду...';
			case 'chat.validationFailed': return 'Помилка валідації. Перевірте формат JSON.';
			case 'chat.retry': return 'Спробувати ще раз';
			case 'chat.resetConfirm': return 'Почати спочатку? Весь прогрес буде втрачено.';
			case 'chat.aiPromptTitle': return 'AI Промпт';
			case 'chat.aiPromptSubtitle': return 'Скопіюйте та вставте в ChatGPT, Claude або Gemini';
			case 'chat.copyPrompt': return 'Копіювати';
			case 'chat.openAiTool': return 'Відкрити AI';
			case 'chat.openChatGPT': return 'Відкрити ChatGPT';
			case 'chat.openClaude': return 'Відкрити Claude';
			case 'chat.iHaveResponse': return 'Вже маю відповідь';
			case 'chat.send': return 'Надіслати';
			case 'chat.proceed': return 'Продовжити';
			case 'chat.urlHint': return 'https://youtube.com/watch?v=...';
			case 'chat.jsonHint': return 'Вставте JSON відповідь тут...';
			case 'chat.errorNetwork': return 'Помилка мережі. Перевірте з\'єднання.';
			case 'chat.errorInvalidUrl': return 'Невірне посилання на YouTube.';
			case 'chat.errorNoTranscript': return 'Субтитри не знайдено. Спробуйте інше відео.';
			case 'prompt.title': return 'Копіювати AI промпт';
			case 'prompt.step1': return '1. Скопіюйте промпт нижче';
			case 'prompt.step2': return '2. Вставте його в ChatGPT, Claude, Gemini тощо.';
			case 'prompt.copyPrompt': return 'Скопіювати промпт';
			case 'prompt.copied': return 'Скопійовано!';
			case 'prompt.nextStep': return 'У мене є відповідь AI — Вставити JSON';
			case 'paste.title': return 'Вставити відповідь AI';
			case 'paste.subtitle': return 'Вставте JSON-відповідь від вашого AI-інструменту';
			case 'paste.hint': return '{\n  "videoTitle": "...",\n  "moments": [...]\n}';
			case 'paste.validate': return 'Перевірити та переглянути моменти';
			case 'geminiStep.title': return 'Запитати Gemini';
			case 'geminiStep.step1Title': return '1. Скопіювати та відкрити Gemini';
			case 'geminiStep.step1Hint': return 'Промпт скопіюється в буфер. Вставте його в Gemini та попросіть смішні моменти.';
			case 'geminiStep.copyOpen': return 'Скопіювати та відкрити Gemini';
			case 'geminiStep.copiedLabel': return 'Промпт скопійовано';
			case 'geminiStep.step2Title': return '2. Вставити відповідь Gemini';
			case 'geminiStep.step2Hint': return 'Поверніться сюди та вставте JSON відповідь нижче';
			case 'geminiStep.validate': return 'Перевірити та переглянути моменти';
			case 'review.title': return 'Огляд моментів';
			case 'review.selectAll': return 'Вибрати все';
			case 'review.deselectAll': return 'Скасувати вибір';
			case 'review.noMoments': return 'У відповіді AI не знайдено моментів.\nПоверніться та згенеруйте заново, коли з\'являться субтитри.';
			case 'review.minSelectionError': return 'Виберіть принаймні 3 моменти для генерації.';
			case 'review.clipDuration': return '{duration}с кліп';
			case 'review.selectedInfo': return '{selected} з {total} вибрано';
			case 'review.generate': return 'Згенерувати {count} кліпів';
			case 'review.generateDisabled': return 'Виберіть моменти для генерації';
			case 'review.tapToLoadPreview': return 'Натисніть, щоб завантажити прев\'ю';
			case 'review.selectMoment': return 'Вибрати момент';
			case 'review.deselectMoment': return 'Скасувати вибір моменту';
			case 'review.selected': return 'Вибрано';
			case 'review.showMore': return 'Показати більше';
			case 'review.showLess': return 'Показати менше';
			case 'processing.title': return 'Генерація кліпів';
			case 'processing.errorTitle': return 'Щось пішло не так';
			case 'processing.goBack': return 'Повернутися до огляду';
			case 'processing.submitting': return 'Надсилання завдання...';
			case 'processing.fetchingInfo': return 'Отримання інформації про відео...';
			case 'processing.downloading': return 'Завантаження відео...';
			case 'processing.cutting': return 'Нарізка кліпів...';
			case 'processing.disclaimer': return 'Завантаження та нарізка вибраних моментів.\nЦе може зайняти кілька хвилин залежно від довжини відео.';
			case 'results.title': return 'Ваші кліпи';
			case 'results.startOver': return 'Почати заново';
			case 'results.noClips': return 'Кліпи не були згенеровані.';
			case 'results.tapToPreview': return 'Натисніть для перегляду';
			case 'results.clipsReady': return '{count} кліпів готово';
			case 'results.downloadHint': return 'Завантаження відкривається в новій вкладці для сумісності з iPhone Safari.';
			case 'results.downloadBlocked': return 'Завантаження заблоковане браузером. Дозвольте pop-up і повторіть.';
			case 'results.playerLoadFailed': return 'Не вдалося завантажити прев\'ю. Спробуйте ще раз.';
			case 'results.copyPostText': return 'Копіювати текст поста';
			case 'results.postTextCopied': return 'Текст поста скопійовано!';
			case 'results.preview': return 'Перегляд';
			case 'results.download': return 'Завантажити';
			default: return null;
		}
	}
}

extension on _StringsEn {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'common.copyLogs': return 'Copy logs';
			case 'common.logsCopied': return 'Logs copied! Paste to AI to diagnose.';
			case 'common.back': return 'Back';
			case 'common.done': return 'Done!';
			case 'common.error': return 'Error';
			case 'common.analyzing': return 'Analyzing...';
			case 'common.analyze': return 'Analyze';
			case 'common.loading': return 'Loading...';
			case 'common.cancel': return 'Cancel';
			case 'common.refresh': return 'Refresh';
			case 'common.toggleDark': return 'Dark Theme';
			case 'common.toggleLight': return 'Light Theme';
			case 'common.paste': return 'Paste';
			case 'analyze.title': return 'Funny Threads AI';
			case 'analyze.subtitle': return 'Turn a YouTube video into viral clips';
			case 'analyze.urlLabel': return 'YouTube URL';
			case 'analyze.urlHint': return 'https://www.youtube.com/watch?v=...';
			case 'analyze.languageLabel': return 'Language profile';
			case 'analyze.languages.en': return 'English';
			case 'analyze.languages.uk': return 'Ukrainian';
			case 'analyze.languages.uk_18': return 'Ukrainian 18+';
			case 'analyze.languages.ru': return 'Russian';
			case 'chat.title': return 'Funny Threads AI';
			case 'chat.welcomeMessage': return 'Hi! I\'ll help you turn YouTube videos into viral clips. Send me a video link.';
			case 'chat.selectLanguagePrompt': return 'Which language should I use for the analysis?';
			case 'chat.thinking': return 'Thinking...';
			case 'chat.analyzingVideo': return 'Analyzing video...';
			case 'chat.videoFound': return 'Found the video! Select a language for generation:';
			case 'chat.buildingPrompt': return 'Preparing AI prompt...';
			case 'chat.promptReady': return 'Prompt ready! Copy it and open your AI tool.';
			case 'chat.promptCopied': return 'Prompt copied!';
			case 'chat.pasteJsonPrompt': return 'Paste the AI JSON response:';
			case 'chat.validating': return 'Validating response...';
			case 'chat.validationSuccess': return 'Great! Found {count} moments. Going to review...';
			case 'chat.validationFailed': return 'Validation error. Please check the JSON format.';
			case 'chat.retry': return 'Try again';
			case 'chat.resetConfirm': return 'Start over? All progress will be lost.';
			case 'chat.aiPromptTitle': return 'AI Prompt';
			case 'chat.aiPromptSubtitle': return 'Copy and paste into ChatGPT, Claude, or Gemini';
			case 'chat.copyPrompt': return 'Copy';
			case 'chat.openAiTool': return 'Open AI Tool';
			case 'chat.openChatGPT': return 'Open ChatGPT';
			case 'chat.openClaude': return 'Open Claude';
			case 'chat.iHaveResponse': return 'I have a response';
			case 'chat.send': return 'Send';
			case 'chat.proceed': return 'Continue';
			case 'chat.urlHint': return 'https://youtube.com/watch?v=...';
			case 'chat.jsonHint': return 'Paste JSON response here...';
			case 'chat.errorNetwork': return 'Network error. Please check your connection.';
			case 'chat.errorInvalidUrl': return 'Invalid YouTube link.';
			case 'chat.errorNoTranscript': return 'Subtitles not found. Try another video.';
			case 'prompt.title': return 'Copy AI Prompt';
			case 'prompt.step1': return '1. Copy the prompt below';
			case 'prompt.step2': return '2. Paste it into ChatGPT, Claude, Gemini, etc.';
			case 'prompt.copyPrompt': return 'Copy Prompt';
			case 'prompt.copied': return 'Copied!';
			case 'prompt.nextStep': return 'I\'ve got the AI response — Paste JSON';
			case 'paste.title': return 'Paste AI Response';
			case 'paste.subtitle': return 'Paste the JSON response from your AI tool';
			case 'paste.hint': return '{\n  "videoTitle": "...",\n  "moments": [...]\n}';
			case 'paste.validate': return 'Validate & Preview Moments';
			case 'geminiStep.title': return 'Ask Gemini';
			case 'geminiStep.step1Title': return '1. Copy & Open Gemini';
			case 'geminiStep.step1Hint': return 'The prompt will be copied to clipboard. Paste it in Gemini and ask for funny moments.';
			case 'geminiStep.copyOpen': return 'Copy & Open Gemini';
			case 'geminiStep.copiedLabel': return 'Prompt copied!';
			case 'geminiStep.step2Title': return '2. Paste Gemini\'s response';
			case 'geminiStep.step2Hint': return 'Come back here and paste the JSON response below';
			case 'geminiStep.validate': return 'Validate & Preview Moments';
			case 'review.title': return 'Review Moments';
			case 'review.selectAll': return 'Select All';
			case 'review.deselectAll': return 'Deselect All';
			case 'review.noMoments': return 'No moments found in AI response.\nGo back and regenerate after transcript is available.';
			case 'review.minSelectionError': return 'Select at least 3 moments to generate.';
			case 'review.clipDuration': return '{duration}s clip';
			case 'review.selectedInfo': return '{selected} of {total} selected';
			case 'review.generate': return 'Generate {count} Video Posts';
			case 'review.generateDisabled': return 'Select moments to generate posts';
			case 'review.tapToLoadPreview': return 'Tap to load preview';
			case 'review.selectMoment': return 'Select moment';
			case 'review.deselectMoment': return 'Deselect moment';
			case 'review.selected': return 'Selected';
			case 'review.showMore': return 'Show more';
			case 'review.showLess': return 'Show less';
			case 'processing.title': return 'Generating Clips';
			case 'processing.errorTitle': return 'Something went wrong';
			case 'processing.goBack': return 'Go back to review';
			case 'processing.submitting': return 'Submitting job...';
			case 'processing.fetchingInfo': return 'Fetching video info...';
			case 'processing.downloading': return 'Downloading video...';
			case 'processing.cutting': return 'Cutting clips...';
			case 'processing.disclaimer': return 'Downloading and cutting your selected moments.\nThis may take a few minutes depending on video length.';
			case 'results.title': return 'Your Clips';
			case 'results.startOver': return 'Start over';
			case 'results.noClips': return 'No clips were generated.';
			case 'results.tapToPreview': return 'Tap to preview';
			case 'results.clipsReady': return '{count} clips ready';
			case 'results.downloadHint': return 'Downloads open in a new tab for iPhone Safari compatibility.';
			case 'results.downloadBlocked': return 'Download blocked by browser. Allow pop-ups and try again.';
			case 'results.playerLoadFailed': return 'Unable to load preview. Try again.';
			case 'results.copyPostText': return 'Copy post text';
			case 'results.postTextCopied': return 'Post text copied!';
			case 'results.preview': return 'Preview';
			case 'results.download': return 'Download';
			default: return null;
		}
	}
}
