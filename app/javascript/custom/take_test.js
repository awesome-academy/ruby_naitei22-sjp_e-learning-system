function initializeTimer() {
  const timerElement = document.getElementById("timer");
  const form = document.querySelector(".test-form");

  if (!timerElement || !form) {
    return;
  }

  const durationInMinutes = timerElement.dataset.duration;
  if (!durationInMinutes || durationInMinutes <= 0) {
    return;
  }

  let timeLeft = durationInMinutes * 60;

  if (window.testTimerInterval) {
    clearInterval(window.testTimerInterval);
  }

  function updateTimer() {
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

    const minutes = Math.floor(timeLeft / 60);
    const seconds = timeLeft % 60;

    timerElement.textContent = `${minutes}:${seconds
      .toString()
      .padStart(2, "0")}`;

    if (timeLeft <= 300) {
      // 5 phút cuối
      timerElement.style.color = "red";
      timerElement.style.fontWeight = "bold";
    } else if (timeLeft <= 600) {
      timerElement.style.color = "orange";
    }
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
