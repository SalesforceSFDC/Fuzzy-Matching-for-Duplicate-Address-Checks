/**
 * Encode a word phonetically
 * 'HeLLLL00 World!'
 *  -> 'HLWRLD'
 *    -> 'H40643'
 *       Which is the same code as 'Hello World!'
 */
public static string Phonetic(string ip, integer max) {

    if (ip == null || ip == '') return '';

    string op = ip.toUpperCase();

    // Encode phonetically similar letters as same number
    op = op.replaceAll('[^BFPVCGJKQSXZDTLMNR]', '0');
    op = op.replaceAll('[BFPV]', '1');
    op = op.replaceAll('[CGJKQSXZ]', '2');
    op = op.replaceAll('[DT]', '3');
    op = op.replaceAll('[L]', '4');
    op = op.replaceAll('[MN]', '5');
    op = op.replaceAll('[R]', '6');

    // Remove double-letters
    string op2 = op.substring(0,1);
    for (integer i=1; i<op.length()-1; i++) {
        string c2 = op.substring(i,i+1);
        if (!op2.endsWith(c2)) op2 += c2;
        //system.debug('******'+op2);
    }

    // Limit length of code returned
    if (max > op2.length()) max = op2.length();

    // Keep first letter of original word
    op2 = ip.substring(0,1) + op2.substring(1, max);

    return op2;
}
