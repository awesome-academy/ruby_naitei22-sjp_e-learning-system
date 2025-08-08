function initializeTimer() {
  const timerElement = document.getElementById("timer");
  const form = document.querySelector(".test-form");
  if (!timerElement || !form) {
    return;
  }

  const initialTimeLeft = timerElement.dataset.timeLeft;
  if (!initialTimeLeft || initialTimeLeft <= 0) {
    timerElement.textContent = "0:00";
    return;
  }
  let timeLeft = parseInt(initialTimeLeft, 10);

  const totalDurationString = timerElement.dataset.totalDuration;
  if (!totalDurationString || totalDurationString <= 0) {
    return;
  }
  const durationInMinutes = parseInt(totalDurationString, 10);

  if (window.testTimerInterval) {
    clearInterval(window.testTimerInterval);
  }

  function updateTimer() {
    const minutes = Math.floor(timeLeft / 60);
    const seconds = timeLeft % 60;
    timerElement.textContent = `${minutes}:${seconds
      .toString()
      .padStart(2, "0")}`;

    const totalDurationInSeconds = durationInMinutes * 60;
    if (timeLeft <= totalDurationInSeconds / 10) {
      timerElement.style.color = "red";
      timerElement.style.fontWeight = "bold";
    } else if (timeLeft <= totalDurationInSeconds / 3) {
      timerElement.style.color = "orange";
    }

    if (timeLeft <= 0) {
      clearInterval(window.testTimerInterval);
      timerElement.textContent = "0:00";
      if (!form.dataset.submitted) {
        form.dataset.submitted = "true";
        form.submit();
      }
      return;
    }

    timeLeft--;
  }

  updateTimer();
  window.testTimerInterval = setInterval(updateTimer, 1000);
}

function cleanupTimer() {
  if (window.testTimerInterval) {
    clearInterval(window.testTimerInterval);
  }
}

document.addEventListener("turbo:load", initializeTimer);
document.addEventListener("turbo:before-visit", cleanupTimer);

export { initializeTimer };
