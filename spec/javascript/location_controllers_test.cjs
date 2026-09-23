const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

function controller(file, geolocation, secure = true) {
  const source = fs.readFileSync(path.join(__dirname, '../../app/javascript/controllers', file), 'utf8')
    .replace(/^import .*$/m, '')
    .replace('export default class', 'globalThis.Subject = class');
  const context = { Controller: class {}, window: { isSecureContext: secure }, navigator: { geolocation },
    HTMLFormElement: { prototype: { submit() { this.submitted = true; } } } };
  vm.createContext(context);
  vm.runInContext(source, context);
  const subject = new context.Subject();
  subject.element = { isConnected: true };
  subject.buttonTarget = { disabled: false };
  subject.statusTarget = { textContent: '' };
  subject.latitudeTarget = { value: '' };
  subject.longitudeTarget = { value: '' };
  return subject;
}
const submit = subject => subject.submit({ preventDefault() {} });

test('check-in waits for location and submits the returned coordinates', () => {
  let success;
  const subject = controller('check_in_controller.js', { getCurrentPosition(ok, fail, options) {
    success = ok;
    assert.equal(options.maximumAge, 0);
  } });
  submit(subject);
  assert.equal(subject.element.submitted, undefined);
  assert.equal(subject.buttonTarget.disabled, true);
  success({ coords: { latitude: 30.6, longitude: -96.3 } });
  assert.equal(subject.latitudeTarget.value, 30.6);
  assert.equal(subject.longitudeTarget.value, -96.3);
  assert.equal(subject.element.submitted, true);
});

test('denied location does not submit and lets the member retry', () => {
  const subject = controller('check_in_controller.js', { getCurrentPosition(ok, fail) { fail({ code: 1 }); } });
  submit(subject);
  assert.equal(subject.element.submitted, undefined);
  assert.equal(subject.buttonTarget.disabled, false);
  assert.match(subject.statusTarget.textContent, /permission was denied/);
});

test('timeout does not submit and explains how to retry', () => {
  const subject = controller('check_in_controller.js', { getCurrentPosition(ok, fail) { fail({ code: 3 }); } });
  submit(subject);
  assert.equal(subject.element.submitted, undefined);
  assert.equal(subject.buttonTarget.disabled, false);
  assert.match(subject.statusTarget.textContent, /try again/);
});

test('insecure context and unsupported location never submit', () => {
  for (const subject of [controller('check_in_controller.js', null), controller('check_in_controller.js', {}, false)]) {
    submit(subject);
    assert.equal(subject.element.submitted, undefined);
    assert.match(subject.statusTarget.textContent, /Location is unavailable/);
  }
});

test('repeated clicks request location only once while waiting', () => {
  let requests = 0;
  const subject = controller('check_in_controller.js', { getCurrentPosition() { requests++; } });
  submit(subject);
  submit(subject);
  assert.equal(requests, 1);
});

test('leaving the page prevents a late callback from submitting', () => {
  let success;
  const subject = controller('check_in_controller.js', { getCurrentPosition(ok) { success = ok; } });
  submit(subject);
  subject.element.isConnected = false;
  success({ coords: { latitude: 30, longitude: -96 } });
  assert.equal(subject.element.submitted, undefined);
});

test('officer location fills coordinates without submitting the event', () => {
  const subject = controller('event_location_controller.js', { getCurrentPosition(ok) {
    ok({ coords: { latitude: 30.61234567, longitude: -96.31234567 } });
  } });
  subject.locate();
  assert.equal(subject.latitudeTarget.value, '30.612346');
  assert.equal(subject.longitudeTarget.value, '-96.312346');
  assert.equal(subject.element.submitted, undefined);
  assert.equal(subject.buttonTarget.disabled, false);
});

test('officer location failure leaves manual coordinates intact', () => {
  const subject = controller('event_location_controller.js', { getCurrentPosition(ok, fail) { fail(); } });
  subject.latitudeTarget.value = '30';
  subject.locate();
  assert.equal(subject.latitudeTarget.value, '30');
  assert.equal(subject.buttonTarget.disabled, false);
  assert.match(subject.statusTarget.textContent, /enter coordinates manually/);
});