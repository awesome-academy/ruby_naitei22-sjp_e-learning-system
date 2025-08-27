// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "jquery";
import "controllers";
import "custom/menu";
import "custom/dropdown";
import "custom/modal";
import "custom/admin_user_courses";
import { createIcons, icons } from "lucide";
import "./custom/take_test";
import "./custom/filter_form";
import "@rails/request.js";

document.addEventListener("turbo:load", () => {
  createIcons({ icons });
});
import "trix";
import "@rails/actiontext";
