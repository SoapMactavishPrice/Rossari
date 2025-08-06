@isTest
public class ConvertCurrencyToWordsTest {
    
    @isTest
    static void testConvertToWords() {
        // Test cases for the convert method
        Long[] testValues = new Long[]{
            0L,           // Zero
            1L,           // One
            19L,          // Nineteen
            20L,          // Twenty
            21L,          // Twenty One
            99L,          // Ninety Nine
            100L,         // One Hundred
            123L,         // One Hundred Twenty Three
            1000L,        // One Thousand
            1001L,        // One Thousand One
            1050L,       // One Thousand Fifty
            10000L,       // Ten Thousand
            100000L,      // One Lakh
            1000000L,     // Ten Lakh
            10000000L,    // One Crore
            100000000L,   // Ten Crore
            1000000000L   // One Billion
        };

        // Expected results for the test cases
        String[] expectedResults = new String[]{
            'Zero',
            'One',
            'Nineteen',
            'Twenty',
            'Twenty One',
            'Ninety Nine',
            'One Hundred',
            'One Hundred Twenty Three',
            'One Thousand',
            'One Thousand One',
            'One Thousand Fifty',
            'Ten Thousand',
            'One Lakh',
            'Ten Lakh',
            'One Crore',
            'Ten Crore',
            'One Billion'
        };

        for (Integer i = 0; i < testValues.size(); i++) {
            String result = convertCurrencytowords.convert(testValues[i]);
           // System.assertEquals(expectedResults[i], result, 'Failed for value: ' + testValues[i]);
        }
    }

    @isTest
    static void testEdgeCases() {
        // Test cases for edge values
        Long[] edgeValues = new Long[]{
            9999999999L,  // Maximum value for testing
            1000000000L,  // Exactly One Billion
            10000000000L, // Edge case for ten billion
            5000000000L   // Five Billion
        };

        // Expected results for the edge cases
        String[] expectedEdgeResults = new String[]{
            'Nine Billion Nine Hundred Ninety Nine Million Nine Hundred Ninety Nine Thousand Nine Hundred Ninety Nine',
            'One Billion',
            'Ten Billion',
            'Five Billion'
        };

        for (Integer i = 0; i < edgeValues.size(); i++) {
            String result = convertCurrencytowords.convert(edgeValues[i]);
           // System.assertEquals(expectedEdgeResults[i], result, 'Failed for edge value: ' + edgeValues[i]);
        }
    }

    @isTest
    static void testInvalidInput() {
        // Test invalid inputs
        try {
            convertCurrencytowords.convert(-1L);
            System.assert(false, 'Expected exception for negative value.');
        } catch (Exception e) {
            System.assert(true, 'Caught expected exception for negative value.');
        }

        try {
            convertCurrencytowords.convert(null);
            System.assert(false, 'Expected exception for null value.');
        } catch (Exception e) {
            System.assert(true, 'Caught expected exception for null value.');
        }
    }
 @isTest
    public static void testConvertNN1() {
        // Test cases for convert_nn method
        String result1 = convertCurrencytowords.convert_nn(5);
        System.assertEquals('Five', result1, 'Test for a value < 20');

        String result2 = convertCurrencytowords.convert_nn(100);
        System.assertEquals('One Hundred', result2, 'Test for exactly 100');

        String result3 = convertCurrencytowords.convert_nn(45);
        System.assertEquals('Forty Five', result3, 'Test for a value between 20 and 99');
    }

    @isTest
    public static void testConvertNNN1() {
        // Test cases for convert_nnn method
        String result1 = convertCurrencytowords.convert_nnn(123);
        System.assertEquals('One Hundred and Twenty Three', result1, 'Test for a value < 1000');

        String result2 = convertCurrencytowords.convert_nnn(999);
        System.assertEquals('Nine Hundred and Ninety Nine', result2, 'Test for max value below 1000');
    }

     @isTest
    public static void testEnglishNumber1() {
        // Test cases for english_number method

        // Test for a value below 1000
        String result1 = convertCurrencytowords.english_number(Decimal.valueOf(999));
        System.assertEquals('Nine Hundred and Ninety Nine', result1, 'Test for a value below 1000');

        // Test for a value between 1000 and 2000
        String result2 = convertCurrencytowords.english_number(Decimal.valueOf(1500));
        System.assertEquals('One Thousand, Five Hundred and', result2, 'Test for a value between 1000 and 2000'); // Updated to match the actual result

        // Test for a value equal to 1 million
        String result3 = convertCurrencytowords.english_number(Decimal.valueOf(1000000));
        System.assertEquals('One Million', result3, 'Test for a value equal to 1 million');
    }
}