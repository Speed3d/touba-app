/**
 * ملف الثوابت المشتركة مع جلب من Remote Config
 * ============================================================================
 *  هذا الملف يحتوي على الثوابت المشتركة بين Cloud Functions و Flutter
 *  الهدف: توحيد القيم ومنع عدم التطابق بين الطرفين
 *
 *  النسخة المقابلة في Flutter:
 *  lib/core/constants/app_constants.dart
 *
 *  ⚠️ مهم: عند تعديل أي قيمة، يُفضل تعديلها في Remote Config.
 * ============================================================================
 */
const admin = require("firebase-admin");

// الثوابت الافتراضية كخلفية (Fallback)
const DEFAULT_RATING_CONSTANTS = {
  recommendedThreshold: 4.5,
  notRecommendedThreshold: 2.5,
  minRatingsForBadge: 10,
  trustedMinRating: 4.5,
  trustedMinCount: 10,
  expertMinRating: 4.8,
  expertMinCount: 20,
  recentRatingsWeight: 2.0,
  recentRatingsCount: 5,
};

const DEFAULT_RATE_LIMIT_CONSTANTS = {
  maxCallsPerMinute: 10,
  windowMs: 60000,
  createServiceRequest: 6,
  useActivationCode: 5,
  validateSubscription: 10,
  adminChangePassword: 3,
};

const DEFAULT_SUBSCRIPTION_CONSTANTS = {
  freeCraftsmenLimit: 100,
  freeSubscriptionDays: 90,
  expiryWarningDays: 3,
};

const DEFAULT_REQUEST_CONSTANTS = {
  dailyRequestLimit: 2,
};

const DEFAULT_BUSINESS_RULES_CONSTANTS = {
  autoCloseNewRequestDays: 3,
  autoCloseOfferedRequestDays: 3,
  autoCloseAcceptedWarningDays: 3,
  autoCloseAcceptedDays: 7,
  autoCloseCompletedDays: 7,
  chatDurationBasicDays: 15,
  chatDurationProDays: 30,
  chatDurationUnlimitedDays: 60,
};

let cachedConstants = null;
let lastFetchTime = 0;
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 دقائق

/**
 * جلب الثوابت محلياً أو من Remote Config
 *  يتم الاحتفاظ بالقيم في الذاكرة لتخفيف الضغط على خوادم Firebase
 * ويتم تحديثها كل 5 دقائق.
 */
async function getConstants() {
  const now = Date.now();
  if (cachedConstants && (now - lastFetchTime < CACHE_TTL_MS)) {
    return cachedConstants;
  }

  try {
    const template = await admin.remoteConfig().getTemplate();
    const params = template.parameters;
    
    // دالة مساعدة لاستخراج القيمة
    const getValue = (key, fallback, parseFn) => {
      if (params[key] && params[key].defaultValue && params[key].defaultValue.value !== undefined) {
        return parseFn(params[key].defaultValue.value);
      }
      return fallback;
    };

    cachedConstants = {
      RATING_CONSTANTS: {
        recommendedThreshold: getValue("recommendedThreshold", DEFAULT_RATING_CONSTANTS.recommendedThreshold, parseFloat),
        notRecommendedThreshold: getValue("notRecommendedThreshold", DEFAULT_RATING_CONSTANTS.notRecommendedThreshold, parseFloat),
        minRatingsForBadge: getValue("minRatingsForBadge", DEFAULT_RATING_CONSTANTS.minRatingsForBadge, parseInt),
        trustedMinRating: getValue("trustedMinRating", DEFAULT_RATING_CONSTANTS.trustedMinRating, parseFloat),
        trustedMinCount: getValue("trustedMinCount", DEFAULT_RATING_CONSTANTS.trustedMinCount, parseInt),
        expertMinRating: getValue("expertMinRating", DEFAULT_RATING_CONSTANTS.expertMinRating, parseFloat),
        expertMinCount: getValue("expertMinCount", DEFAULT_RATING_CONSTANTS.expertMinCount, parseInt),
        recentRatingsWeight: getValue("recentRatingsWeight", DEFAULT_RATING_CONSTANTS.recentRatingsWeight, parseFloat),
        recentRatingsCount: getValue("recentRatingsCount", DEFAULT_RATING_CONSTANTS.recentRatingsCount, parseInt),
      },
      RATE_LIMIT_CONSTANTS: {
        maxCallsPerMinute: getValue("maxCallsPerMinute", DEFAULT_RATE_LIMIT_CONSTANTS.maxCallsPerMinute, parseInt),
        windowMs: getValue("windowMs", DEFAULT_RATE_LIMIT_CONSTANTS.windowMs, parseInt),
        createServiceRequest: getValue("createServiceRequest", DEFAULT_RATE_LIMIT_CONSTANTS.createServiceRequest, parseInt),
        useActivationCode: getValue("useActivationCode", DEFAULT_RATE_LIMIT_CONSTANTS.useActivationCode, parseInt),
        validateSubscription: getValue("validateSubscription", DEFAULT_RATE_LIMIT_CONSTANTS.validateSubscription, parseInt),
        adminChangePassword: getValue("adminChangePassword", DEFAULT_RATE_LIMIT_CONSTANTS.adminChangePassword, parseInt),
      },
      SUBSCRIPTION_CONSTANTS: {
        freeCraftsmenLimit: getValue("freeCraftsmenLimit", DEFAULT_SUBSCRIPTION_CONSTANTS.freeCraftsmenLimit, parseInt),
        freeSubscriptionDays: getValue("freeSubscriptionDays", DEFAULT_SUBSCRIPTION_CONSTANTS.freeSubscriptionDays, parseInt),
        expiryWarningDays: getValue("expiryWarningDays", DEFAULT_SUBSCRIPTION_CONSTANTS.expiryWarningDays, parseInt),
      },
      REQUEST_CONSTANTS: {
        dailyRequestLimit: getValue("dailyRequestLimit", DEFAULT_REQUEST_CONSTANTS.dailyRequestLimit, parseInt),
      },
    };
    
    lastFetchTime = now;
    return cachedConstants;
  } catch (error) {
    console.error("خطأ في جلب Remote Config Template (استخدام القيم الافتراضية):", error);
    return cachedConstants || {
      RATING_CONSTANTS: DEFAULT_RATING_CONSTANTS,
      RATE_LIMIT_CONSTANTS: DEFAULT_RATE_LIMIT_CONSTANTS,
      SUBSCRIPTION_CONSTANTS: DEFAULT_SUBSCRIPTION_CONSTANTS,
      REQUEST_CONSTANTS: DEFAULT_REQUEST_CONSTANTS,
    };
  }
}

module.exports = {
  getConstants,
  DEFAULT_BUSINESS_RULES_CONSTANTS,
};
