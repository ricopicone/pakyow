const fs = require("fs");
const path = require("path");
const dirs = p => fs.readdirSync(p).filter(f => fs.statSync(path.join(p, f)).isDirectory());

const jsdom = require("jsdom");
const { JSDOM } = jsdom;

global.pw = require("../src/index");
import {default as Transformer} from "../src/internal/transformer";

const caseDir = "__tests__/support/cases";

const removeWhitespace = function (string) {
  return string.replace(/\n/g, "").replace(/[ ]+\</g, "<").replace(/\>[ ]+\</g, "><").replace(/\>[ ]+/g, ">");
}

const comparable = function (dom) {
  // remove the templates from the result (making it easier to compare)
  for (let script of dom.querySelectorAll("script")) {
    script.parentNode.removeChild(script)
  }

  // strip all whitespace from the result (making it easier to compare)
  return removeWhitespace(
    dom.querySelector("body").outerHTML
  );
}

for (let caseName of dirs(caseDir)) {
  // if (caseName != "versioned_props_with_no_default_used_and_then_presented") {
  //   continue;
  // }

  test(`case: ${caseName}`, () => {
    let initial = fs.readFileSync(
      path.join(caseDir, caseName, "initial.html"),
      "utf8"
    );

    let result = fs.readFileSync(
      path.join(caseDir, caseName, "result.html"),
      "utf8"
    );

    let transformations = JSON.parse(
      fs.readFileSync(
        path.join(caseDir, caseName, "transformations.json"),
        "utf8"
      )
    );

    let initialDOM = new JSDOM(initial);
    let resultDOM = new JSDOM(result);

    // set the top level transformation id
    document.querySelector("html").setAttribute("data-t", initialDOM.window.document.querySelector("html").getAttribute("data-t"))

    // replace the rest of the document
    document.querySelector("html").innerHTML = initialDOM.window.document.querySelector("html").innerHTML;

    // apply the transformations
    for (let transformation of transformations) {
      new Transformer(transformation);
    }

    // finally, make the assertion
    expect(comparable(document)).toEqual(comparable(resultDOM.window.document));
  });
}
