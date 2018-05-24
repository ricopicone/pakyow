var components = {};
var instances = [];
var broadcasts = {};
var observer;

export default class {
  static get components() {
    return components;
  }

  static get instances() {
    return instances;
  }

  static register(name, component) {
    components[name] = component;
  }

  static init(node) {
    if (!observer) {
      observer = new MutationObserver((evt) => {
        if (evt[0].removedNodes) {
          for (let node of evt[0].removedNodes) {
            let component = instances.find((component) => {
              return component.view.node === node;
            });

            if (component) {
              component.channels.forEach((channel) => {
                component.ignore(channel);
              });

              instances.splice(instances.indexOf(component), 1);
            }
          }
        }
      });

      observer.observe(document.body, { childList: true });
    }

    for (let view of new pw.View(node).qs("*[data-ui]")) {
      if (!instances.find((component) => { return component.view.node === view.node })) {
        let object = components[view.node.dataset.ui] || this.create();
        let instance = new object(view, this.parseConfig(view.node.dataset.config));
        instances.push(instance);
        instance.ready();
      }
    }
  }

  static broadcast(channel, payload) {
    for (let tuple of (broadcasts[channel] || [])) {
      tuple[0].trigger(channel, payload);
    }
  }

  static parseConfig(configString) {
    if (typeof configString === "undefined") {
      return {};
    }

    return configString.split(";").reduce((config, option) => {
      let key_value = option.trim().split(":");
      config[key_value[0].trim()] = key_value[1].trim();
      return config;
    }, {});
  }

  static clearObserver() {
    if (observer) {
      observer.disconnect();
      observer = null;
    }
  }

  static create() {
    var component = function(view, config = {}) {
      this.view = view;
      this.config = config;
      this.channels = [];
    };

    component.prototype.ready = function () {
      // intentionally empty
    };

    component.prototype.listen = function (channel, callback) {
      this.view.node.addEventListener(channel, (evt) => {
        callback.call(this, evt.detail);
      });

      if (!broadcasts[channel]) {
        broadcasts[channel] = [];
      }

      broadcasts[channel].push([this, callback]);
      this.channels.push(channel);
    };

    component.prototype.ignore = function (channel) {
      broadcasts[channel].filter((tuple) => {
        return tuple[0].view.node === this.view.node;
      }).forEach((tuple) => {
        this.view.node.removeEventListener(channel, tuple[1]);
        broadcasts[channel].splice(broadcasts[channel].indexOf(tuple), 1);
      });

      this.channels.splice(this.channels.indexOf(channel), 1);
    };

    component.prototype.trigger = function (channel, payload) {
      this.view.node.dispatchEvent(
        new CustomEvent(channel, { detail: payload })
      );
    };

    component.prototype.bubble = function (channel, payload) {
      this.view.node.dispatchEvent(
        new CustomEvent(channel, { bubbles: true, detail: payload })
      );
    };

    component.prototype.trickle = function (channel, payload) {
      this.trigger(channel, payload);

      for (let view of this.view.qs("*[data-ui]")) {
        let tuple = broadcasts[channel].find((tuple) => {
          return tuple[0].view.node === view.node;
        });

        if (tuple) {
          tuple[0].trigger(channel, payload);
        }
      }
    }

    return component;
  }
}