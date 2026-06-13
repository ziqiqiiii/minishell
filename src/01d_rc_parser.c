#include "rc_parser.h"
#include <string.h>

t_rc_line_type	classify_rc_line(const char *line, const char **value_out)
{
	const char	*s;

	s = line;
	while (*s == ' ' || *s == '\t')
		s++;
	if (*s == '\0')
	{
		*value_out = NULL;
		return (RC_LINE_EMPTY);
	}
	if (strncmp(s, "PATH=", 5) == 0)
	{
		*value_out = s + 5;
		return (RC_LINE_PATH);
	}
	*value_out = s;
	return (RC_LINE_COMMAND);
}
