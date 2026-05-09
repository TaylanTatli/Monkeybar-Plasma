"use strict";

function formatDateKey(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function getDates(asISOString, showCurrentWeekOnly, weekStartDay, daysToShow) {
  if (asISOString === undefined) {
    asISOString = true;
  }
  if (showCurrentWeekOnly === undefined) {
    showCurrentWeekOnly = false;
  }
  if (weekStartDay === undefined) {
    weekStartDay = 1;
  }
  if (daysToShow === undefined) {
    daysToShow = 7;
  }

  const dates = [];
  const today = new Date();

  if (showCurrentWeekOnly) {
    const currentDay = today.getDay();
    let daysToSubtract = currentDay - weekStartDay;

    if (daysToSubtract < 0) {
      daysToSubtract += 7;
    }

    const weekStart = new Date(today);
    weekStart.setDate(today.getDate() - daysToSubtract);

    for (let index = 0; index < daysToShow; index += 1) {
      const date = new Date(weekStart);
      date.setDate(weekStart.getDate() + index);
      dates.push(asISOString ? formatDateKey(date) : date);
    }
  } else {
    for (let index = daysToShow - 1; index >= 0; index -= 1) {
      const date = new Date(today);
      date.setDate(date.getDate() - index);
      dates.push(asISOString ? formatDateKey(date) : date);
    }
  }

  return dates;
}

function requestJson(url, headers = {}) {
  return new Promise((resolve, reject) => {
    const request = new XMLHttpRequest();
    request.open("GET", url, true);
    request.setRequestHeader("User-Agent", "Plasma MonkeyBar");

    for (const [key, value] of Object.entries(headers)) {
      request.setRequestHeader(key, value);
    }

    request.onreadystatechange = function onReadyStateChange() {
      if (request.readyState !== XMLHttpRequest.DONE) {
        return;
      }

      if (request.status >= 200 && request.status < 300) {
        try {
          resolve(JSON.parse(request.responseText));
        } catch (error) {
          reject(error);
        }
      } else {
        reject(new Error(`HTTP ${request.status}`));
      }
    };

    request.onerror = function onError() {
      reject(new Error("Network error"));
    };

    request.send();
  });
}

function parseTestActivity(testActivity, targetDates) {
  if (!testActivity || !Array.isArray(testActivity.testsByDays)) {
    return Array(targetDates.length).fill(0);
  }

  const activityMap = new Map();
  const lastDay = new Date(testActivity.lastDay);

  for (let index = testActivity.testsByDays.length - 1; index >= 0; index -= 1) {
    const date = new Date(lastDay);
    date.setDate(lastDay.getDate() - (testActivity.testsByDays.length - 1 - index));
    activityMap.set(formatDateKey(date), testActivity.testsByDays[index] || 0);
  }

  return targetDates.map(date => activityMap.get(date) || 0);
}

function buildProfilePayload(profileData, targetDates) {
  return {
    activity: profileData.testActivity ? parseTestActivity(profileData.testActivity, targetDates) : Array(targetDates.length).fill(0),
    streak: profileData.streak || 0,
    maxStreak: profileData.maxStreak || 0
  };
}

function buildActivityPayload(profileData, activityData, targetDates) {
  return {
    activity: profileData.testActivity ? parseTestActivity(profileData.testActivity, targetDates) : parseTestActivity(activityData, targetDates),
    streak: profileData.streak || 0,
    maxStreak: profileData.maxStreak || 0
  };
}

function fetchTypingActivity(username, apeKey, showCurrentWeekOnly, weekStartDay, daysToShow) {
  if (showCurrentWeekOnly === undefined) {
    showCurrentWeekOnly = false;
  }
  if (weekStartDay === undefined) {
    weekStartDay = 1;
  }
  if (daysToShow === undefined) {
    daysToShow = 7;
  }

  if (!username) {
    return Array(daysToShow).fill(0);
  }

  const targetDates = getDates(true, showCurrentWeekOnly, weekStartDay, daysToShow);

  return requestJson(`https://api.monkeytype.com/users/${username}/profile`, apeKey ? {
    Authorization: `ApeKey ${apeKey}`
  } : {})
    .then(result => {
      if (!result || !result.data) {
        throw new Error("Unexpected profile response");
      }

      const profileData = result.data;

      if (!apeKey) {
        return buildProfilePayload(profileData, targetDates);
      }

      return requestJson("https://api.monkeytype.com/users/currentTestActivity", {
        Authorization: `ApeKey ${apeKey}`
      }).then(activityResult => {
        if (!activityResult || !activityResult.data) {
          throw new Error("Unexpected activity response");
        }

        return buildActivityPayload(profileData, activityResult.data, targetDates);
      });
    })
    .catch(error => {
      console.error(`MonkeyBar: ${error}`);
      return {
        activity: Array(targetDates.length).fill(0),
        streak: 0,
        maxStreak: 0
      };
    });
}