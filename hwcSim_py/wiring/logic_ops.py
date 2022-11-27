'''
case OP_NEQUAL:
		case OP_LESS:
		case OP_GREATER:
		case OP_LESSEQ:
		case OP_GREATEREQ:
		case OP_BITAND:
		case OP_AND:
		case OP_BITOR:
		case OP_OR:
		case OP_XOR:
		case OP_PLUS:
		case OP_MINUS:
		case OP_TIMES:
		case OP_DIVIDE:
		case OP_MODULO:
		case OP_CONCAT:
'''

from wiring.bit_dictionary import Bit_Dictionary

class LogicOp(object):

    def __init__(self, readers, writers, name):
        self.readers = readers
        self.writers = writers
        self.name    = name

    def getName(self):
        return self.name

    def getReaders(self):
        return self.readers
    
    def getWriters(self):
        return self.writers

    def __str__(self):
        logic_str = ""
        
        logic_str += "NAME:    " + self.name         + "\n"
        logic_str += "READERS: " + str(self.readers) + "\n"
        logic_str += "WRITERS: " + str(self.writers) + "\n"
        
        return logic_str


class NOT(LogicOp):

    def __init__(self, readers, writers, name):
        LogicOp.__init__(self, readers, writers, name)

        self.val_a = None
        self.out   = None

    def deliver_a(self, val):
        self.val_a = val

        # try to evaluate operation
        self.evaluate_op()

    def evaluate_op(self):
        if self.val_a == None or self.out != None:
            return

        if self.val_a == 1:
            self.out = 0
    
        elif self.val_a == 0:
            self.out = 1

        else:   # Catch unexpected behavior
            return

        for reader in self.readers:
            reader(self.out)


    def get_lambda(self):
        return lambda val: deliver_a(val)


class AND(LogicOp):

    def __init__(self, readers, writers, name, fromBits, toBit):
        LogicOp.__init__(self, readers, writers, name)

        self.val_a = None
        self.val_b = None
        self.out   = None
        self.fromBits = fromBits
        self.toBit = toBit

    def deliver_a(self, val):
        self.val_a = val

        # try to evaluate operation
        self.evaluate_op()

    def deliver_b(self, val):
        self.val_b = val

        # try to evaulate operation
        self.evaluate_op()

    def evaluate_op(self):
        if self.val_a == None or self.val_b == None or self.out != None:
            return

        val = self.val_a + self.val_b

        # True if both 0 or both 1
        if val == 2:
            self.out = 1
        else:
            self.out = 0

        for reader in self.readers:
            reader(self.out)

    def stringType():
        return "AND"

    def get_lambda():
        return

class OR(LogicOp):

    def __init__(self, readers, writers, name, fromBits, toBit):
        LogicOp.__init__(self, readers, writers, name)

        self.val_a = None
        self.val_b = None
        self.out   = None
        self.fromBits = fromBits
        self.toBit = toBit

    def deliver_a(self, val):
        self.val_a = val

        # try to evaluate operation
        self.evaluate_op()

    def deliver_b(self, val):
        self.val_b = val

        # try to evaluate operation
        self.evaluate_op()

    def evaluate_op(self):
        if self.val_a == None or self.val_b == None or self.out != None:
            return

        val = self.val_a + self.val_b

        # True if both 0 or both 1
        if val > 0:
            self.out = 1
        else:
            self.out = 0

        for reader in self.readers:
            reader(self.out)

    def get_lambda():
        return

class XOR(LogicOp):

    def __init__(self, readers, writers, name, fromBits, toBit):
        LogicOp.__init__(self, readers, writers, name)

        self.val_a = None
        self.val_b = None
        self.out   = None
        self.fromBits = fromBits
        self.toBit = toBit

    def deliver_a(self, val):
        self.val_a = val

        # try to evaluate operation
        self.evaluate_op()

    def deliver_b(self, val):
        self.val_b = val

        # try to evaluate operation
        self.evaluate_op()

    def evaluate_op(self):
        if self.val_a == None or self.val_b == None or self.out != None:
            return

        val = self.val_a + self.val_b

        # True if only a or b is 1
        if val == 1:
            self.out = 1
        else:
            self.out = 0

        for reader in self.readers:
            reader(self.out)

    def get_lambda():
        return


class EQ(LogicOp):

    def __init__(self, readers, writers, name, fromBits, toBit):
        LogicOp.__init__(self, readers, writers, name)
        
        self.val_a = None
        self.val_b = None
        self.out   = None
        self.fromBits = fromBits
        self.toBit = toBit

    def deliver_a(self, val):
        self.val_a = val

        # try to evaluate operation
        self.evaluate_op()

    def deliver_b(self, val):
        self.val_b = val

        # try to evaluate operation
        self.evaluate_op()

    def evaluate_op(self):
        if self.val_a == None or self.val_b == None or self.out != None:
            return

        val = self.val_a + self.val_b

        # True if both XOR of two is 0
        if val != 1:
            self.out = 1
        else:
            self.out = 0

        for reader in self.readers:
            reader(self.out)

    def get_lambda():
        return

class NEQ(LogicOp):

    def __init__(self, readers, writers, name, fromBits, toBit):
        LogicOp.__init__(self, readers, writers, name)
        
        self.val_a = None
        self.val_b = None
        self.out   = None
        self.fromBits = fromBits
        self.toBit = toBit

    def deliver_a(self, val):
        self.val_a = val

        # try to evaluate operation
        self.evaluate_op()

    def deliver_b(self, val):
        self.val_b = val

        # try to evaluate operation
        self.evaluate_op()

    def evaluate_op(self):
        if self.val_a == None or self.val_b == None or self.out != None:
            return

        val = self.val_a + self.val_b

        # True if both XOR of two is 1
        if val == 1:
            self.out = 1
        else:
            self.out = 0

        for reader in self.readers:
            reader(self.out)

    def get_lambda():
        return

class GT(LogicOp):

    def __init__(self, readers, writers, name, fromBits, toBit):
        LogicOp.__init__(self, readers, writers, name)
        
        self.val_a = None
        self.val_b = None
        self.out   = None
        self.fromBits = fromBits
        self.toBit = toBit

    def deliver_a(self, val):
        self.val_a = val

        # try to evaluate operation
        self.evaluate_op()

    def deliver_b(self, val):
        self.val_b = val

        # try to evaluate operation
        self.evaluate_op()

    def evaluate_op(self):
        if self.val_a == None or self.val_b == None or self.out != None:
            return

        # True if a > b
        if self.val_a > self.val_b:
            self.out = 1
        else:
            self.out = 0

        for reader in self.readers:
            reader(self.out)

    def get_lambda():
        return

class GE(LogicOp):

    def __init__(self, readers, writers, name, fromBits, toBit):
        LogicOp.__init__(self, readers, writers, name)
        
        self.val_a = None
        self.val_b = None
        self.out   = None
        self.fromBits = fromBits
        self.toBit = toBit

    def deliver_a(self, val):
        self.val_a = val

        # try to evaluate operation
        self.evaluate_op()

    def deliver_b(self, val):
        self.val_b = val

        # try to evaluate operation
        self.evaluate_op()

    def evaluate_op(self):
        if self.val_a == None or self.val_b == None or self.out != None:
            return

        # True if a > b
        if self.val_a >= self.val_b:
            self.out = 1
        else:
            self.out = 0

        for reader in self.readers:
            reader(self.out)

    def get_lambda():
        return

class LT(LogicOp):

    def __init__(self, readers, writers, name, fromBits, toBit):
        LogicOp.__init__(self, readers, writers, name)
        
        self.val_a = None
        self.val_b = None
        self.out   = None
        self.fromBits = fromBits
        self.toBit = toBit

    def deliver_a(self, val):
        self.val_a = val

        # try to evaluate operation
        self.evaluate_op()

    def deliver_b(self, val):
        self.val_b = val

        # try to evaluate operation
        self.evaluate_op()

    def evaluate_op(self):
        if self.val_a == None or self.val_b == None or self.out != None:
            return

        # True if a > b
        if self.val_a < self.val_b:
            self.out = 1
        else:
            self.out = 0

        for reader in self.readers:
            reader(self.out)

    def get_lambda():
        return

class LE(LogicOp):

    def __init__(self, readers, writers, name, fromBits, toBit):
        LogicOp.__init__(self, readers, writers, name)
        
        self.val_a = None
        self.val_b = None
        self.out   = None
        self.fromBits = fromBits
        self.toBit = toBit

    def deliver_a(self, val):
        self.val_a = val

        # try to evaluate operation
        self.evaluate_op()

    def deliver_b(self, val):
        self.val_b = val

        # try to evaluate operation
        self.evaluate_op()

    def evaluate_op(self):
        if self.val_a == None or self.val_b == None or self.out != None:
            return

        # True if a > b
        if self.val_a <= self.val_b:
            self.out = 1
        else:
            self.out = 0

        for reader in self.readers:
            reader(self.out)

    def get_lambda():
        return
    
class assertOp(LogicOp):

    def __init__(self, assertBit):

        self.BIT = assertBit
        self.val_a = None
        self.out   = None

    def deliver_a(self, val):
        self.val_a = val
        # try to evaluate operation
        self.evaluate_op()

    def evaluate_op(self):
        if self.val_a == None:
            return

        if self.val_a != 1:
            print("ASSERT FAILED AT BIT " + str(self.BIT))
            assert False

    def get_lambda():
        return

class condConnOp(LogicOp):

    def __init__(self, toBit, fromBit, bitValue, connections):

        self.producedOutput = False
        self.condLambdas = {}
        self.toBit = toBit
        self.fromBit = fromBit
        self.bitValue = bitValue
        self.connections = connections

    def evaluate_op(self, condition):
        if self.condLambdas[condition][1] == False or self.condLambdas[condition][2] == False:
            return

        if self.producedOutput:
            print("Conditional connection has made a short circuit.")
            assert False
        else:
            #Setting flag to true, to flag that output has been provided from this connection.
            self.producedOutput = True

            # We create a connection object and immediately deliver.
            completeConn = connOp(self.condLambdas[condition][0], self.toBit, self.fromBit)
            self.connections.append(completeConn)
            completeConn.deliver(self.condLambdas[condition][1], self.bitValue)
    
    # Three items in the list. First item is lambda to be called, second is val, third is if condition was met.
    # Create a conditional connection to the same location, we use the condition as a identifier.
    def addConn(self, condition, readers):
        self.condLambdas[condition] =  [readers, False, False]

    # Deliver value bit
    def setVal(self, condition, val):
        self.condLambdas[condition][1] = val
        self.evaluate_op(condition)
    
    # Deliver condition bit
    def setCondition(self, condition, val):
        self.condLambdas[condition][2] = val
        self.evaluate_op(condition)

    def get_lambda():
        return

class connOp(LogicOp):

    def __init__(self, readers, toBit, fromBit):
        
        # Reference of readers from bit dictionary.
        self.readers = readers
        self.toBit = toBit
        self.fromBit = fromBit
        self.condLambdas = {}

    def deliver(self, val, bitValue):
        bitValue[self.toBit] = val
        bitValue[self.fromBit] = val
        # Run all the readers from the reference obtained on compile time from bit dictionary.
        for reader in self.readers:
            reader(val)

    def get_lambda():
        return
