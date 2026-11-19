const ALIAS_REGEX = /\b([a-zA-Z0-9_-]+dir)\b/;

exports.decorateTerm = (Term, { React }) => {
  return class extends React.Component {
    constructor(props, context) {
      super(props, context);
      this._handleClick = this._handleClick.bind(this);
    }

    _extractAliasName(event) {
      const target = event && event.target;
      if (!target) return null;

      const text = (target.textContent || "").trim();
      const match = text.match(ALIAS_REGEX);
      if (match && match[1]) {
        return match[1];
      }

      const selection = window.getSelection ? String(window.getSelection()).trim() : "";
      const selMatch = selection.match(ALIAS_REGEX);
      return selMatch ? selMatch[1] : null;
    }

    _handleClick(event) {
      if (!event.altKey) return;

      const aliasName = this._extractAliasName(event);
      if (!aliasName) return;

      const uid = this.props.uid;
      if (uid && window.rpc) {
        window.rpc.emit("data", { uid, data: `${aliasName}\r` });
      }
    }

    render() {
      return React.createElement(
        "div",
        {
          style: { width: "100%", height: "100%" },
          onClick: this._handleClick,
        },
        React.createElement(Term, this.props)
      );
    }
  };
};
