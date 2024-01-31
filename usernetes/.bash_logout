# ~/.bash_logout
# The individual login shell cleanup file, executed when a login shell exits.

if [ "${TERM-}" = linux ]; then
	case "$(tty 2>/dev/null)" in
		/dev/tty[0-9]*|/dev/vc/*|/dev/xvc*)
			clear ;;
	esac
fi
